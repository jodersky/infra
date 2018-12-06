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
    "www.crashbox.io",
    "ip.crashbox.io",
    "git.crashbox.io",
    "dl.crashbox.io",
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

resource "hcloud_server" "peter" {
  name        = "peter"
  image       = "debian-9"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys    = ["${hcloud_ssh_key.root.name}"]
}

# volumes contain persistent storage and thus need to be initialized
# manually
data "hcloud_volume" "master" {
  name = "master"
}

# note that this module not idempotent: a second application requires
# destroying the server resource first
module "peter_provision" {
  source                 = "./mount_and_provision"
  host                   = "${hcloud_server.peter.ipv4_address}"
  server_id              = "${hcloud_server.peter.id}"
  volume_id              = "${data.hcloud_volume.master.id}"
  tls_private_key        = "${acme_certificate.certificate.private_key_pem}"
  tls_certificate        = "${acme_certificate.certificate.certificate_pem}"
  tls_issuer_certificate = "${acme_certificate.certificate.issuer_pem}"
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

resource "cloudflare_record" "record_www" {
  domain = "crashbox.io"
  name   = "www"
  value  = "${cloudflare_record.peter_a.hostname}"
  type   = "CNAME"
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

resource "cloudflare_record" "record_a" {
  domain = "crashbox.io"
  name   = "@"
  value  = "${hcloud_server.peter.ipv4_address}"
  type   = "A"
}

resource "cloudflare_record" "record_aaaa" {
  domain = "crashbox.io"
  name   = "@"
  value  = "${hcloud_server.peter.ipv6_address}1"
  type   = "AAAA"
}
