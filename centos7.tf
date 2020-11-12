terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}

# Pretty standard libvirt setup of domain
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos7-qcow2" {
  name   = "centos7-qcow2"
  pool   = "default"
  source = "./images/CentOS-7-x86_64-GenericCloud.qcow2"
  format = "qcow2"
}

#Bootstrap off cloud-init. Change root password, and add meeeeeee
data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.yml")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  pool           = "default"
}

resource "libvirt_domain" "domain-centos7" {
  name   = "centos7-terraform"
  memory = "1024"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # stupid networking. It looses it's mac address if you don't add one. The provider is kinda unstable.
  network_interface {
    mac = "52:54:00:6c:3c:02"
    network_name = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.centos7-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
  
  # The meaty part. Provisions podman and adds amazee app1 to k3s
  provisioner "file" {
    source      = "./scripts/provision.sh"
    destination = "/tmp/provision.sh"
    connection {
      host = libvirt_domain.domain-centos7.network_interface.0.addresses.0
      type = "ssh"
      user = "wfisher"
      timeout = "2m"
    }
  }

  # Make app1 a tar-ball. Kinda hacky, but it works
  provisioner "local-exec" {
    command = "tar czvf app1.tar.gz ./app1"
  }

  provisioner "file" {
    source = "app1.tar.gz"
    destination = "/tmp/app1.tar.gz"
    connection {
      host     = libvirt_domain.domain-centos7.network_interface.0.addresses.0
      type     = "ssh"
      user     = "wfisher"
      timeout = "2m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh"
    ]
    connection {
      host     = libvirt_domain.domain-centos7.network_interface.0.addresses.0
      type     = "ssh"
      user     = "wfisher"
      timeout = "2m"
    }
  }

}

