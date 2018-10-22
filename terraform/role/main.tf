variable "host" {
  type = "string"
}

variable "id" {
  type = "string"
}

variable "roles" {
  type = "list"
}

variable "secret_cloudflare_token" {
  type = "string"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "jakob@odersky.com"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "${var.host}"
  subject_alternative_names = "${formatlist("%s.crashbox.io", var.roles)}"

  dns_challenge {
    provider = "cloudflare"

    config {
      CLOUDFLARE_EMAIL   = "jakob@odersky.com"
      CLOUDFLARE_API_KEY = "${var.secret_cloudflare_token}"
    }
  }
}

resource "cloudflare_record" "role_cname" {
  count = "${length(var.roles)}"

  domain = "crashbox.io"
  name   = "${element(var.roles, count.index)}"
  value  = "${var.host}"
  type   = "CNAME"
}

resource "null_resource" "role_config" {
  triggers = {
    host_id         = "${var.id}"
    config_packages = "${join(" ", sort(formatlist("crashbox-%s-config", var.roles)))}"
  }

  connection {
    host = "${var.host}"
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
    content     = "${acme_certificate.certificate.private_key_pem}"
    destination = "/etc/ssl/private/server.key.pem"
  }

  provisioner "file" {
    source      = "${path.root}/../packages/target/archive"
    destination = "/usr/local/share/"
  }

  provisioner "remote-exec" {
    inline = [
      "echo deb [trusted=yes] file:/usr/local/share/archive ./ > /etc/apt/sources.list.d/local-archive.list",
      "apt update --quiet=2",
      "apt install --quiet=2 --yes ${null_resource.role_config.triggers.config_packages}",
    ]
  }
}

output "roles" {
  value = "${var.roles}"
}
