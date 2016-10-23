provider "scaleway" {}

variable "k8stoken" {}

# https://github.com/docker/docker/issues/22305
# kernel 4.5.0 - 4.5.1 don't work well with docker
data "scaleway_bootscript" "docker" {
  architecture = "x86_64"
  name_filter = "4.8.3 docker #1"
}

data "scaleway_image" "xenial" {
  architecture = "x86_64"
  name         = "Ubuntu Xenial"
}

data "template_file" "master-userdata" {
  template = "${file("templates/master.sh")}"

  vars {
    k8stoken = "${var.k8stoken}"
  }
}

resource "scaleway_server" "k8s-master" {
  type                = "VC1S"
  name                = "k8s-master"
  dynamic_ip_required = true
  bootscript          = "${data.scaleway_bootscript.docker.id}"
  image               = "${data.scaleway_image.xenial.id}"

  connection {
    type         = "ssh"
    user         = "root"
    host         = "${self.public_ip}"
  }

  provisioner "file" {
    content     = "${data.template_file.master-userdata.rendered}"
    destination = "/tmp/master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/master.sh",
      "sudo /tmp/master.sh",
    ]
  }

  tags = ["k8s-master"]
}

data "template_file" "worker-userdata" {
  template = "${file("templates/worker.sh")}"

  vars {
    k8stoken = "${var.k8stoken}"
    masterIP = "${scaleway_server.k8s-master.private_ip}"
  }
}

resource "scaleway_server" "k8s-worker" {
  type                = "VC1S"
  name                = "k8s-worker-${count.index+1}"
  dynamic_ip_required = true
  bootscript          = "${data.scaleway_bootscript.docker.id}"
  image               = "${data.scaleway_image.xenial.id}"
  count               = 2

  connection {
    type         = "ssh"
    user         = "root"
    host         = "${self.public_ip}"
  }

  provisioner "file" {
    content     = "${data.template_file.worker-userdata.rendered}"
    destination = "/tmp/worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/worker.sh",
      "sudo /tmp/worker.sh",
    ]
  }

  tags = ["k8s-worker-${count.index}"]
}

output "master_ip" {
  value = "${scaleway_server.k8s-master.public_ip}"
}
