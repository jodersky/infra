variable "server_fqdn" {
  type = "string"
}

variable "server_id" {
  type = "string"
}

resource "hcloud_volume" "master" {
  name      = "master"
  size      = 50
  server_id = "${var.server_id}"
}

# this is only run once if the volume id changes
resource "null_resource" "volume_format" {
  triggers = {
    volume_id = "${hcloud_volume.master.id}"
  }

  connection {
    host = "${var.server_fqdn}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkfs.ext4 ${hcloud_volume.master.linux_device}",
    ]
  }
}

resource "null_resource" "volume_mount" {
  triggers = {
    server_id = "${var.server_id}"
    volume_id = "${hcloud_volume.master.id}"
  }

  connection {
    host = "${var.server_fqdn}"
  }

  provisioner "file" {
    content = <<EOF
[Unit]
Description=Mount /srv directory

[Mount]
What=${hcloud_volume.master.linux_device}
Where=/srv
Type=ext4
Options=defaults
EOF

    destination = "/etc/systemd/system/srv.mount"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable srv.mount",
      "systemctl start srv.mount",
    ]
  }
}

output "server_id" {
  value = "${var.server_id}"
}
