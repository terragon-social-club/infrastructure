variable "mike_key" {
  type = "string"
  default = "2e:05:a5:d1:0f:9e:d8:4e:06:af:20:e7:d4:8b:7b:96"
}

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

variable "keys" {
  default = []
}

variable "region" {
  default = "nyc1"
}

variable "image" {
  default = "freebsd-11-2-x64-zfs"
}

variable "size" {
  default = "512mb"
}

resource "digitalocean_droplet" "salt_minion" {
  private_networking = true
  backups = true
  region = "${var.region}"
  image = "${var.image}"
  name = "${var.name}"
  size = "${var.size}"
  ssh_keys = ["${var.keys}"]
  ipv6 = false
  
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "5m"
  }

  provisioner "remote-exec" "salt_download_install_configure" {
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
    source = "${path.module}/../98-minion-config.conf"
    destination = "/usr/local/etc/salt/minion.d/98-minion-config.conf"
  }
 
}

resource "null_resource" "generate_minion_key_master" {
  depends_on = ["digitalocean_droplet.salt_minion"]
  triggers {
    id = "${digitalocean_droplet.salt_minion.id}"
  }

  connection {
    host = "${var.salt_master_public_ip_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" "minion_keys" {
    inline = [
      "salt-key --gen-keys=${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "cp ${var.name}.pub /usr/local/etc/salt/pki/master/minions/${var.name}",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pub root@${digitalocean_droplet.salt_minion.ipv4_address_private}:/usr/local/etc/salt/pki/minion/minion.pub",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pem root@${digitalocean_droplet.salt_minion.ipv4_address_private}:/usr/local/etc/salt/pki/minion/minion.pem",
      "rm ${var.name}.pub",
      "rm ${var.name}.pem",
      "chmod 600 /usr/local/etc/salt/pki/minion/minion.pem",
      "chmod 600 /usr/local/etc/salt/pki/minion/minion.pub"
    ]
    
  }
  
}

resource "null_resource" "salt_minion_start" {
  depends_on = ["null_resource.generate_minion_key_master"]
  triggers {
    id = "${digitalocean_droplet.salt_minion.id}"
  }
  
  connection {
    host = "${digitalocean_droplet.salt_minion.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }
  
  provisioner "remote-exec" "start_minion" {
    inline = [
      "service salt_minion start"
    ]
    
  }
 
}

resource "digitalocean_record" "salt_minion" {
  domain = "${var.domain_id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_droplet.salt_minion.ipv4_address}"
}

data "template_file" "grains" {
  template = "${file("${path.module}/../grains.tpl")}"
  vars {
    roles = "${join("\n", var.salt_minion_roles)}"
    fqdn = "${var.name}.terragon.us"
  }
  
}
