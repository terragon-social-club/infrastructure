variable "salt_minion_roles" {
  default = ["minion"]
}

variable "domain_id" { }
variable "name" { }

variable "keys" {
  type = "list"
}

variable "provision" {
  default = 1
}

variable "salt_master_private_ip_address" { }
variable "salt_master_public_ip_address" { }

variable "region" {
  default = "nyc1"
}

variable "image" {
  default = "freebsd-12-x64-zfs"
}

variable "size" {
  default = "512mb"
}

resource "digitalocean_droplet" "salt_minion" {
  count = "${var.provision ? 1 : 0}"
  #private_networking = false
  private_networking = true
  backups = false
  region = "${var.region}"
  image = "${var.image}"
  name = "${var.name}"
  size = "${var.size}"
  ssh_keys = "${var.keys}"
  ipv6 = false
  
  connection {
    host = "${self.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file("/usr/local/jenkins/.ssh/id_rsa")}"
    timeout = "5m"
  }

  provisioner "remote-exec" {
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

  provisioner "remote-exec" {
    connection {
      host = "${var.salt_master_public_ip_address}"
      user = "root"
      type = "ssh"
      private_key = "${file("/usr/local/jenkins/.ssh/id_rsa")}"
      timeout = "2m"
    }
    
    inline = [
      "salt-key --gen-keys=${var.name}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "cp ${var.name}.pub /usr/local/etc/salt/pki/master/minions/${var.name}",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pub root@${digitalocean_droplet.salt_minion[0].ipv4_address}:/usr/local/etc/salt/pki/minion/minion.pub",
      "scp -o 'StrictHostKeyChecking no' ${var.name}.pem root@${digitalocean_droplet.salt_minion[0].ipv4_address}:/usr/local/etc/salt/pki/minion/minion.pem",
      "rm ${var.name}.pub",
      "rm ${var.name}.pem",
    ]
    
  }
  
  provisioner "remote-exec" {
    inline = [
      "service salt_minion start"
    ]
    
  }

  provisioner "remote-exec" {
    when = "destroy"
    
    connection {
      host = "${var.salt_master_public_ip_address}"
      user = "root"
      type = "ssh"
      private_key = "${file("/usr/local/jenkins/.ssh/id_rsa")}"
      timeout = "2m"
    }
    
    inline = [
      "salt-key -d ${var.name} -y",
    ]
    
  }
 
}

resource "digitalocean_record" "salt_minion" {
  count = "${var.provision ? 1 : 0}" 
  domain = "${var.domain_id}"
  type = "A"
  name = "${var.name}"
  value = "${digitalocean_droplet.salt_minion[0].ipv4_address}"
}

data "template_file" "grains" {
  template = "${file("${path.module}/../grains.tpl")}"
  vars = {
    roles = join("\n", [for role in var.salt_minion_roles : "  - ${role}"])
    fqdn = "${var.name}.terragon.us"
  }
  
}

output "salt_minion_private_ip_address" {
  value = "${digitalocean_droplet.salt_minion[0].ipv4_address_private}"
}

output "salt_minion_public_ip_address" {
  value = "${digitalocean_droplet.salt_minion[0].ipv4_address}"
}

output "provision" {
  value = "${var.provision}"
}
