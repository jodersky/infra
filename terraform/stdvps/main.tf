variable "ssh_key_name" {
  type = "string"
}

variable "location" {
  type = "string"
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
