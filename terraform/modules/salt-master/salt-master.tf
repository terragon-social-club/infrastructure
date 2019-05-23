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

variable "tld" {
  default = ""
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

#resource "digitalocean_ssh_key" "salt_master_key" {
#  depends_on = ["null_resource.copy_master_public_key"]
#  
#  name = "Salt Master ${var.name} Key"
#  public_key = "${data.local_file.master_public_key.content}"
#}

resource "digitalocean_droplet" "salt_master" {
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

  provisioner "remote-exec" "salt_git" {
    inline = [
      "env ASSUME_ALWAYS_YES=YES pkg install git",
      "env ASSUME_ALWAYS_YES=YES pkg install devel/py-gitpython"
    ]
    
  }

  provisioner "remote-exec" "master_key" {
    inline = [
      "ssh-keygen -t rsa -N \"\" -f /root/.ssh/id_rsa"
    ]
    
  }
  
}

# Commented code is related to an idea around generating a new key when master is provisioned,
# and treating master as a bastion server from then on out. Bastion implmentation in terraform
# is pretty much worthless (see https://github.com/hashicorp/terraform/issues/6263) so tabling
# this for now. Must keep marching forward!
#
#resource "null_resource" "copy_master_public_key" {
#  depends_on = ["digitalocean_droplet.salt_master"]
#
#  triggers {
#    id = "${digitalocean_droplet.salt_master.id}"
#  }
#  
#  provisioner "local-exec" {
#    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${digitalocean_droplet.salt_master.ipv4_address}:/root/.ssh/id_rsa.pub /tmp/salt_master.pub"
#  }
#  
#}
#
#resource "digitalocean_ssh_key" "salt_master_key" {
#  depends_on = ["null_resource.copy_master_public_key"]
#  
#  name = "Salt Master ${var.name} Key"
#  public_key = "${data.local_file.master_public_key.content}"
#}
#
#data "local_file" "master_public_key" {
#  depends_on = ["null_resource.copy_master_public_key"]
#  
#  filename = "/tmp/salt_master.pub"
#}
#
#output "salt_master_pk_fingerprint" {
#  value = "${digitalocean_ssh_key.salt_master_key.fingerprint}"
#}

resource "digitalocean_record" "salt_master" {
  # depends_on = ["null_resource.copy_master_public_key"]
  
  domain = "${var.domain_id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_droplet.salt_master.ipv4_address_private}"
}

resource "null_resource" "master_install_configure" {
  depends_on = ["digitalocean_record.salt_master"]

  triggers {
    id = "${digitalocean_droplet.salt_master.id}"
  }
  
  connection {
    host = "${digitalocean_droplet.salt_master.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "5m"
  }

  provisioner "remote-exec" "salt_download" {
    inline = [
      "fetch -o /tmp/bootstrap-salt.sh https://bootstrap.saltstack.com",
      "env sh /tmp/bootstrap-salt.sh -x python3 -X -M -A ${digitalocean_droplet.salt_master.ipv4_address_private} -i ${var.name}",
      "mkdir -p /usr/local/etc/salt/master.d"
    ]
    
  }

  provisioner "file" "configure_master" {
    content = "${data.template_file.master_config.rendered}"
    destination = "/usr/local/etc/salt/master.d/99-master-config.conf"
  }

  provisioner "file" "configure_minion" {
    source = "${path.module}/../98-minion-config.conf"
    destination = "/usr/local/etc/salt/minion.d/98-minion-config.conf"
  }

  provisioner "remote-exec" "generate_keys" {
    inline = [
      "salt-key --gen-keys=${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "mkdir -p /usr/local/etc/salt/pki/minion",
      "cp ${var.name}.pub /usr/local/etc/salt/pki/master/minions/${var.name}",
      "mv ${var.name}.pub /usr/local/etc/salt/pki/minion/minion.pub",
      "mv ${var.name}.pem /usr/local/etc/salt/pki/minion/minion.pem"
    ]
    
  }

  provisioner "file" "grains" {
    content = "${data.template_file.grains.rendered}"
    destination = "/usr/local/etc/salt/grains"
  }

  # Master ssh config (move to salt?)
  provisioner "file" "configure_ssh_client" {
    source = "../salt/files/unix/root/.ssh/config"
    destination = "/root/.ssh/config"
  }

  provisioner "remote-exec" "start_salt" {
    inline = [
      "service salt_master start",
      "sleep 60",
      "service salt_minion start"
    ]
    
  }
  
}

data "template_file" "grains" {
  template = "${file("${path.module}/../grains.tpl")}"
  vars {
    roles = "${join("\n", var.salt_minion_roles)}"
    fqdn = "${var.name}.terragon.us"
  }
  
}

data "template_file" "master_config" {
  template = "${file("${path.module}/../99-master-config.conf.tpl")}"
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

