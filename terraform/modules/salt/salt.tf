variable "master" {
  default = false
}

variable "minion" {
  default = false
}

variable "salt_master_private_ip_address" {
  default = ""
}

variable "salt_master_public_ip_address" {
  default = ""
}

variable "salt_master_fqdn" {
  default = ""
}
variable "salt_minion_roles" {
  default = []
}
variable "domain_id" {
  default = ""
}
variable "name" {}
variable "key" {
  default = []
}
variable "tld" {
  default = ""
}
variable "create_tld" {
  default = false
}
variable "skip_minion_domain" {
  default = false
}

variable "region" {
  default = "nyc1"
}

variable "image" {
  default = "freebsd-11-1-x64"
}

variable "size" {
  default = "512mb"
}

variable "is_bsd" {
  default = 1
}

variable "is_ubuntu" {
  default = 0
}

variable "static_ip" {
  default = 0
}

resource "digitalocean_droplet" "salt_master" {
  count = "${var.master}"
  
  private_networking = true
  backups = true
  region = "${var.region}"
  image = "${var.image}"
  name = "${var.name}"
  size = "${var.size}"
  ssh_keys = ["${var.key}"]
  ipv6 = false
  
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "5m"
  }

  provisioner "remote-exec" "salt-git" {
    inline = [
      "env ASSUME_ALWAYS_YES=YES pkg install git",
      "env ASSUME_ALWAYS_YES=YES pkg install devel/py-gitpython"
    ]
    
  }

  provisioner "file" {
    source = "config/ssh/key"
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "file" {
    source = "config/ssh/key.pub"
    destination = "/root/.ssh/id_rsa.pub"
  }

  provisioner "remote-exec" "salt-perms" {
    inline = [
      "chmod 600 /root/.ssh/id_rsa"
    ]
    
  }
  
}

resource "null_resource" "master_install" {
  count = "${var.master}"
  depends_on = ["digitalocean_droplet.salt_master"]

  triggers {
    id = "${digitalocean_droplet.salt_master.id}"
  }
  
  connection {
    host = "${digitalocean_droplet.salt_master.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" "salt-download" {
    inline = [
      "fetch -o /tmp/bootstrap-salt.sh https://bootstrap.saltstack.com",
      "env IGNORE_OSVERSION=yes sh /tmp/bootstrap-salt.sh -M -X -A ${digitalocean_droplet.salt_master.ipv4_address_private} -i ${var.name}",
      "mkdir -p /usr/local/etc/salt/master.d"
    ]
    
  }

  provisioner "file" {
    content = "${data.template_file.master_config.rendered}"
    destination = "/usr/local/etc/salt/master.d/99-master-config.conf"
  }

  provisioner "file" {
    source = "${path.module}/98-minion-config.conf"
    destination = "/usr/local/etc/salt/minion.d/98-minion-config.conf"
  }
  
}

resource "null_resource" "generate_minion_master_key" {
  count = "${var.master}"
  depends_on = ["null_resource.master_install"]
  
  triggers {
    id = "${digitalocean_droplet.salt_master.id}"
  }

  connection {
    host = "${digitalocean_droplet.salt_master.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "salt-key --gen-keys=${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "mkdir -p /usr/local/etc/salt/pki/minion",
      "cp ${var.name}.pub /usr/local/etc/salt/pki/master/minions/${var.name}",
      "mv ${var.name}.pub /usr/local/etc/salt/pki/minion/minion.pub",
      "mv ${var.name}.pem /usr/local/etc/salt/pki/minion/minion.pem"
    ]
    
  }

  provisioner "file" {
    content = "${data.template_file.grains.rendered}"
    destination = "/usr/local/etc/salt/grains"
  }
  
}

resource "null_resource" "master_start" {
  count = "${var.master}"
  depends_on = ["null_resource.generate_minion_master_key"]
  
  triggers {
    id = "${digitalocean_droplet.salt_master.id}"
  }

  connection {
    host = "${digitalocean_droplet.salt_master.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "file" {
    source = "../salt/files/unix/root/.ssh/config"
    destination = "/root/.ssh/config"
  }

  provisioner "remote-exec" {
    inline = [
      "service salt_master start",
      "service salt_minion start"
    ]
    
  }
  
}

resource "digitalocean_record" "salt_master" {
  count = "${var.master}"
  depends_on = ["null_resource.master_start"]
  domain = "${var.domain_id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_droplet.salt_master.ipv4_address_private}"
}

resource "digitalocean_droplet" "salt_minion_bsd" {
  count = "${var.minion && var.is_bsd ? 1 : 0}"
  depends_on = ["digitalocean_record.salt_master"]
  private_networking = true
  backups = true
  region = "${var.region}"
  image = "${var.image}"
  name = "${var.name}"
  size = "${var.size}"
  ssh_keys = ["${var.key}"]
  ipv6 = false
  
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" "salt_download_install" {
    inline = [
      "fetch -o /tmp/bootstrap-salt.sh https://bootstrap.saltstack.com",
      "sh /tmp/bootstrap-salt.sh -P -X -A ${var.salt_master_private_ip_address} -i ${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/minion",
    ]
    
  }

  provisioner "file" {
    content = "${data.template_file.grains.rendered}"
    destination = "/usr/local/etc/salt/grains"
  }

  provisioner "file" {
    source = "${path.module}/98-minion-config.conf"
    destination = "/usr/local/etc/salt/minion.d/98-minion-config.conf"
  }
 
}

resource "digitalocean_droplet" "salt_minion_ubuntu" {
  count = "${var.minion && var.is_ubuntu ? 1 : 0}"
  depends_on = ["digitalocean_record.salt_master"]
  private_networking = true
  backups = true
  region = "${var.region}"
  image = "${var.image}"
  name = "${var.name}"
  size = "${var.size}"
  ssh_keys = ["${var.key}"]
  ipv6 = false
  
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" "salt_download_install_ubuntu" {
    inline = [
      "wget -O bootstrap-salt.sh https://bootstrap.saltstack.com",
      "sh bootstrap-salt.sh -P -X -A ${var.salt_master_private_ip_address} -i ${var.name}",
      "mkdir -p /etc/salt/pki/minion",
    ]
    
  }

  provisioner "file" {
    content = "${data.template_file.grains.rendered}"
    destination = "/etc/salt/grains"
  }

  provisioner "file" {
    source = "${path.module}/98-minion-config.conf"
    destination = "/etc/salt/minion.d/98-minion-config.conf"
  }
 
}

resource "null_resource" "generate_minion_key_bsd" {
  count = "${var.minion && var.is_bsd ? 1 : 0}"
  depends_on = ["digitalocean_droplet.salt_minion_bsd"]
  triggers {
    id = "${digitalocean_droplet.salt_minion_bsd.id}"
  }

  connection {
    host = "${var.salt_master_public_ip_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "salt-key --gen-keys=${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "cp ${var.name}.pub /usr/local/etc/salt/pki/master/minions/${var.name}",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pub root@${digitalocean_droplet.salt_minion_bsd.ipv4_address_private}:/usr/local/etc/salt/pki/minion/minion.pub",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pem root@${digitalocean_droplet.salt_minion_bsd.ipv4_address_private}:/usr/local/etc/salt/pki/minion/minion.pem",
      "rm ${var.name}.pub",
      "rm ${var.name}.pem"
    ]
    
  }
  
}

resource "null_resource" "generate_minion_key_ubuntu" {
  count = "${var.minion && var.is_ubuntu ? 1 : 0}"
  depends_on = ["digitalocean_droplet.salt_minion_ubuntu"]
  triggers {
    id = "${digitalocean_droplet.salt_minion_ubuntu.id}"
  }

  connection {
    host = "${var.salt_master_public_ip_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "salt-key --gen-keys=${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "cp ${var.name}.pub /usr/local/etc/salt/pki/master/minions/${var.name}",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pub root@${digitalocean_droplet.salt_minion_ubuntu.ipv4_address_private}:/etc/salt/pki/minion/minion.pub",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pem root@${digitalocean_droplet.salt_minion_ubuntu.ipv4_address_private}:/etc/salt/pki/minion/minion.pem",
      "rm ${var.name}.pub",
      "rm ${var.name}.pem"
    ]
    
  }
  
}

resource "null_resource" "minion_start_bsd" {
  count = "${var.minion && var.is_bsd ? 1 : 0}"
  
  triggers {
    id = "${digitalocean_droplet.salt_minion_bsd.id}"
  }

  depends_on = ["null_resource.generate_minion_key_bsd"]

  connection {
    host = "${digitalocean_droplet.salt_minion_bsd.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /usr/local/etc/salt/pki/minion/minion.pem",
      "chmod 600 /usr/local/etc/salt/pki/minion/minion.pub",
      "service salt_minion start"
    ]
    
  }
  
}

resource "null_resource" "minion_start_ubuntu" {
  count = "${var.minion && var.is_ubuntu ? 1 : 0}"
  
  triggers {
    id = "${digitalocean_droplet.salt_minion_ubuntu.id}"
  }

  depends_on = ["null_resource.generate_minion_key_ubuntu"]

  connection {
    host = "${digitalocean_droplet.salt_minion_ubuntu.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /etc/salt/pki/minion/minion.pem",
      "chmod 600 /etc/salt/pki/minion/minion.pub",
      "service salt-minion start"
    ]
    
  }
  
}

resource "digitalocean_floating_ip" "minion_floating_ip" {
  count = "${var.create_tld}"
  region = "nyc1"
  droplet_id = "${digitalocean_droplet.salt_minion_bsd.id}"
}

resource "digitalocean_floating_ip" "minion_static_ip_ubuntu" {
  count = "${var.static_ip && var.is_ubuntu ? 1 : 0}"
  region = "nyc1"
  droplet_id = "${digitalocean_droplet.salt_minion_ubuntu.id}"
}

resource "digitalocean_floating_ip" "minion_static_ip_bsd" {
  count = "${var.static_ip && var.is_bsd ? 1 : 0}"
  region = "nyc1"
  droplet_id = "${digitalocean_droplet.salt_minion_bsd.id}"
}

resource "digitalocean_domain" "minion_tld" {
  count = "${var.create_tld}"
  name = "${var.tld}"
  ip_address = "${digitalocean_floating_ip.minion_floating_ip.ip_address}"
}

resource "digitalocean_record" "salt_minion_bsd" {
  count = "${var.minion && var.is_bsd && !var.skip_minion_domain ? 1 : 0}"
  domain = "${var.domain_id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_droplet.salt_minion_bsd.ipv4_address}"
}

resource "digitalocean_record" "salt_minion_ubuntu" {
  count = "${var.minion && var.is_ubuntu && !var.skip_minion_domain ? 1 : 0}"
  domain = "${var.domain_id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_droplet.salt_minion_ubuntu.ipv4_address}"
}

resource "digitalocean_record" "salt_minion_with_root" {
  count = "${var.skip_minion_domain}"
  domain = "${digitalocean_domain.minion_tld.id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_floating_ip.minion_floating_ip.ip_address}"
}

data "template_file" "grains" {
  template = "${file("${path.module}/grains.tpl")}"
  vars {
    roles = "${join("\n", var.salt_minion_roles)}"
    fqdn = "${var.name}.terragon.us"
  }
  
}

data "template_file" "master_config" {
  count = "${var.master}"
  template = "${file("${path.module}/99-master-config.conf.tpl")}"
  vars {
    private_ip = "${digitalocean_droplet.salt_master.ipv4_address_private}"
  }
  
}

output "salt_master_private_ip_address" {
  value = "${digitalocean_droplet.salt_master.ipv4_address_private}"
}

output "salt_master_public_ip_address" {
  value = "${digitalocean_droplet.salt_master.ipv4_address}"
}

output "salt_master_fqdn" {
  value = "${digitalocean_record.salt_master.fqdn}"
}

#output "domain_id" {
#  value = "${digitalocean_domain.minion_tld.id}"
#}
