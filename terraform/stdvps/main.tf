variable "ssh_key_name" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "volume_name" {
  type = "string"
  default = ""
}

resource "random_id" "server" {
  prefix      = "peter-"
  byte_length = 2
}

resource "hcloud_server" "server" {
  name        = "${random_id.server.hex}.crashbox.io"
  image       = "debian-9"
  server_type = "cx11"
  location    = "${var.location}"
  ssh_keys    = ["${var.ssh_key_name}"]
}

resource "cloudflare_record" "record_a" {
  domain = "crashbox.io"
  name   = "${hcloud_server.server.name}"
  value  = "${hcloud_server.server.ipv4_address}"
  type   = "A"
}

resource "cloudflare_record" "record_aaaa" {
  domain = "crashbox.io"
  name   = "${hcloud_server.server.name}"
  value  = "${hcloud_server.server.ipv6_address}1"
  type   = "AAAA"
}

resource "hcloud_volume" "master" {
  count = "${var.volume_name == "" ? 0 : 1}"
  name = "${var.volume_name}"
  size = 50
  server_id = "${hcloud_server.server.id}"
}

# volumes contain persistent storage and thus need to be initialized manually
resource "null_resource" "volume_mount" {
  count = "${var.volume_name == "" ? 0 : 1}"

  triggers = {
    server_id = "${hcloud_server.server.id}"
    volume_id = "${hcloud_volume.master.id}"
  }

  connection {
    host = "${hcloud_server.server.ipv4_address}"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /mnt/storage"]
  }

  provisioner "file" {
    content = <<EOF
[Unit]
Description=Mount /mnt/storage directory

[Mount]
What=${hcloud_volume.master.linux_device}
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
      "systemctl enable --now home.mount"
    ]
  }
}

output "ipv4" {
  value = "${hcloud_server.server.ipv4_address}"
}

output "ipv6" {
  value = "${hcloud_server.server.ipv6_address}"
}

output "fqdn" {
  value = "${cloudflare_record.record_aaaa.hostname}"
}

output "id" {
  value = "${hcloud_server.server.id}"
}

output "name" {
  value = "${hcloud_server.server.name}"
}
