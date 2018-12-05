variable "secret_hcloud_token" {
  type = "string"
}

variable "secret_cloudflare_token" {
  type = "string"
}

provider "hcloud" {
  token = "${var.secret_hcloud_token}"
}

provider "cloudflare" {
  email = "jakob@odersky.com"
  token = "${var.secret_cloudflare_token}"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

############################################################

resource "hcloud_ssh_key" "root" {
  name       = "root"
  public_key = "${file("root-ssh-key")}"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "jakob@odersky.com"
}

resource "acme_certificate" "certificate" {
  account_key_pem = "${acme_registration.registration.account_key_pem}"
  common_name     = "crashbox.io"

  subject_alternative_names = [
    "ip.crashbox.io",
    "git.crashbox.io",
  ]

  dns_challenge {
    provider = "cloudflare"

    config {
      CLOUDFLARE_EMAIL   = "jakob@odersky.com"
      CLOUDFLARE_API_KEY = "${var.secret_cloudflare_token}"
    }
  }
}

resource "cloudflare_record" "record_caa" {
  domain = "crashbox.io"
  name   = "crashbox.io"

  data = {
    flags = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }

  type = "CAA"
}

resource "random_id" "peter" {
  prefix      = "peter-"
  byte_length = 2
}

resource "hcloud_server" "peter" {
  name        = "${random_id.peter.hex}"
  image       = "debian-9"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys    = ["${hcloud_ssh_key.root.name}"]

  provisioner "file" {
    content     = "${acme_certificate.certificate.private_key_pem}"
    destination = "/etc/ssl/private/server.key.pem"
  }

  provisioner "file" {
    content     = "${acme_certificate.certificate.certificate_pem}"
    destination = "/etc/ssl/server.cert.pem"
  }

  provisioner "file" {
    content     = "${acme_certificate.certificate.issuer_pem}"
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

module "peter_mount_volume" {
  source      = "./mount_volume"
  volume_name = "master"
  host        = "${hcloud_server.peter.ipv4_address}"
  server_id   = "${hcloud_server.peter.id}"
}

resource "cloudflare_record" "peter_a" {
  domain = "crashbox.io"
  name   = "${hcloud_server.peter.name}"
  value  = "${hcloud_server.peter.ipv4_address}"
  type   = "A"
}

resource "cloudflare_record" "peter_aaaa" {
  domain = "crashbox.io"
  name   = "${hcloud_server.peter.name}"
  value  = "${hcloud_server.peter.ipv6_address}1"
  type   = "AAAA"
}

resource "cloudflare_record" "record_ip" {
  domain = "crashbox.io"
  name   = "ip"
  value  = "${cloudflare_record.peter_a.hostname}"
  type   = "CNAME"
}

resource "cloudflare_record" "record_git" {
  domain = "crashbox.io"
  name   = "git"
  value  = "${cloudflare_record.peter_a.hostname}"
  type   = "CNAME"
}
