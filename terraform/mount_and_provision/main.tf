variable "host" {
  type = "string"
}

variable "volume_id" {
  type = "string"
}

variable "server_id" {
  type = "string"
}

variable "tls_private_key" {
  type = "string"
}

variable "tls_certificate" {
  type = "string"
}

variable "tls_issuer_certificate" {
  type = "string"
}

# volumes contain persistent storage and thus need to be initialized
# manually
data "hcloud_volume" "volume" {
  id = "${var.volume_id}"
}

resource "hcloud_volume_attachment" "volume_attachment" {
  volume_id = "${data.hcloud_volume.volume.id}"
  server_id = "${var.server_id}"
}

resource "null_resource" "volume_mount" {
  triggers = {
    attachement_id = "${hcloud_volume_attachment.volume_attachment.id}"
  }

  connection {
    host = "${var.host}"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /mnt/storage"]
  }

  provisioner "file" {
    content = <<EOF
[Unit]
Description=Mount /mnt/storage directory

[Mount]
What=${data.hcloud_volume.volume.linux_device}
Where=/mnt/storage
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target
EOF

    destination = "/etc/systemd/system/mnt-storage.mount"
  }

  provisioner "file" {
    content = <<EOF
[Unit]
Description=Mount /srv to persistent volume storage
After=mnt-storage.mount
BindsTo=mnt-storage.mount

[Mount]
What=/mnt/storage/srv
Where=/srv
Type=ext4
Options=bind

[Install]
WantedBy=multi-user.target
EOF

    destination = "/etc/systemd/system/srv.mount"
  }

  provisioner "file" {
    content = <<EOF
[Unit]
Description=Mount /home to persistent volume storage
After=mnt-storage.mount
BindsTo=mnt-storage.mount

[Mount]
What=/mnt/storage/home
Where=/home
Type=ext4
Options=bind

[Install]
WantedBy=multi-user.target
EOF

    destination = "/etc/systemd/system/home.mount"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable --now mnt-storage.mount",
      "systemctl enable --now srv.mount",
      "systemctl enable --now home.mount",
    ]
  }

  provisioner "file" {
    content     = "${var.tls_private_key}"
    destination = "/etc/ssl/private/server.key.pem"
  }

  provisioner "file" {
    content     = "${var.tls_certificate}"
    destination = "/etc/ssl/server.cert.pem"
  }

  provisioner "file" {
    content     = "${var.tls_issuer_certificate}"
    destination = "/etc/ssl/issuer.cert.pem"
  }

  provisioner "file" {
    source      = "./provision"
    destination = "/usr/local/share/"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/share/provision/provision",
      "/usr/local/share/provision/provision --force",
    ]
  }
}
