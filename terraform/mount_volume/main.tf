variable "volume_name" {
  type = "string"
}

variable "host" {
  type = "string"
}

variable "server_id" {
  type = "string"
}

# volumes contain persistent storage and thus need to be initialized
# manually
data "hcloud_volume" "master" {
  name = "${var.volume_name}"
}

resource "hcloud_volume_attachment" "master_attachment" {
  volume_id = "${data.hcloud_volume.master.id}"
  server_id = "${var.server_id}"
}

resource "null_resource" "volume_mount" {
  triggers = {
    attachement_id = "${hcloud_volume_attachment.master_attachment.id}"
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
What=${data.hcloud_volume.master.linux_device}
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
      "systemctl enable mnt-storage.mount",
      "systemctl enable srv.mount",
      "systemctl enable home.mount",
      "systemctl reboot",
    ]
  }
}
