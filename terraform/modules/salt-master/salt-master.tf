variable "salt_minion_roles" {
  default = ["master"]
}

variable "domain_id" { }
variable "name" { }

variable "keys" {
  type = list
}

variable "region" {
  default = "nyc1"
}

variable "image" {
  default = "freebsd-12-x64-zfs"
}

variable "size" {
  default = "512mb"
}

resource "digitalocean_droplet" "salt_master" {
  private_networking = true
  backups = false
  region = var.region
  image = var.image
  name = var.name
  size = var.size
  ssh_keys = var.keys
  ipv6 = false
}

resource "digitalocean_record" "salt_master" {
  domain = var.domain_id
  type = "A"
  name = var.name
  value = digitalocean_droplet.salt_master.ipv4_address
}

resource "digitalocean_record" "salt_master_private" {
  domain = var.domain_id
  type = "A"
  name = "${var.name}.private"
  value = digitalocean_droplet.salt_master.ipv4_address_private
}

resource "digitalocean_firewall" "ssh_public_access" {
  name="Public-To-Master"
  droplet_ids = [digitalocean_droplet.salt_master.id]
  
  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  
}

resource "digitalocean_firewall" "all_outbound" {
  name="All-Salt-Master-Outbound"
  droplet_ids = [digitalocean_droplet.salt_master.id]

  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  
  outbound_rule {
    protocol = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }
  
  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  
}

resource "tls_private_key" "master_key" {
  algorithm = "RSA"
}

resource "digitalocean_ssh_key" "salt_master" {
  name = "Salt Master"
  public_key = tls_private_key.master_key.public_key_openssh
}

resource "null_resource" "master_prep" {
  depends_on = [
    digitalocean_firewall.ssh_public_access,
    digitalocean_firewall.all_outbound
  ]

  triggers = {
    ids = digitalocean_droplet.salt_master.id
  }
  
  connection {
    host = digitalocean_droplet.salt_master.ipv4_address
    user = "root"
    type = "ssh"
    timeout = "5m"
  }

  provisioner "local-exec" {
    when = destroy
    command = "git rm ${path.module}/keys/${self.id}.pub || true"
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -f ${path.module}/keys/${self.id}.pub || true"
  }
  
  provisioner "remote-exec" {
    inline = [
      "env ASSUME_ALWAYS_YES=YES pkg install git",
      "env ASSUME_ALWAYS_YES=YES pkg install devel/py-gitpython"
    ]
    
  }

  provisioner "remote-exec" {
    inline = [
      "ssh-keygen -t rsa -N \"\" -f /root/.ssh/id_rsa"
    ]
    
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/keys"
  }
  
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${digitalocean_droplet.salt_master.ipv4_address}:/root/.ssh/id_rsa.pub ${path.module}/keys/${digitalocean_droplet.salt_master.id}.pub"
  }

  provisioner "remote-exec" {
    inline = [
      "fetch -o /tmp/bootstrap-salt.sh https://bootstrap.saltstack.com",
      "env sh /tmp/bootstrap-salt.sh -x python3 -X -M -A ${digitalocean_droplet.salt_master.ipv4_address_private} -i ${var.name}",
      "mkdir -p /usr/local/etc/salt/master.d"
    ]
    
  }

  provisioner "file" {
    content = data.template_file.master_config.rendered
    destination = "/usr/local/etc/salt/master.d/99-master-config.conf"
  }

  provisioner "file" {
    source = "${path.module}/../98-minion-config.conf"
    destination = "/usr/local/etc/salt/minion.d/98-minion-config.conf"
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
    content = data.template_file.grains.rendered
    destination = "/usr/local/etc/salt/grains"
  }

  provisioner "remote-exec" {
    inline = [
      "service salt_master start",
      "sleep 60",
      "service salt_minion start"
    ]
    
  }
  
}

data "template_file" "grains" {
  template = file("${path.module}/../grains.tpl")
  vars = {
    roles = join("\n", [for role in var.salt_minion_roles : "  - ${role}"])
    fqdn = "${var.name}.terragon.us"
  }
  
}

data "template_file" "master_config" {
  template = file("${path.module}/../99-master-config.conf.tpl")
  vars = {
    private_ip = digitalocean_droplet.salt_master.ipv4_address_private
  }
  
}

output "salt_master_private_ip_address" {
  value = digitalocean_droplet.salt_master.ipv4_address_private
}

output "salt_master_public_ip_address" {
  value = digitalocean_droplet.salt_master.ipv4_address
}

output "salt_master_fqdn" {
  value = digitalocean_record.salt_master.fqdn
}

output "salt_master_ssh_fingerprint" {
  value = digitalocean_ssh_key.salt_master.fingerprint
}

output "droplet_id" {
  value = digitalocean_droplet.salt_master.id
}
