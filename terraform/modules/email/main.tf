variable "secret_cloudflare_token" {}

variable "domain" {
  description = "Domain name of email addresses."
}

variable "server_ipv4" {
  description = "IP address of primary mail server."
}

variable "server_ipv6" {
  description = "IP address of primary mail server."
}

variable "server_id" {
  description = "Unique server ID that will trigger this module, if changed."
}

resource "tls_private_key" "tls_mail" {
  algorithm = "RSA"
}

resource "acme_registration" "tls_mail" {
  account_key_pem = "${tls_private_key.tls_mail.private_key_pem}"
  email_address   = "jakob@odersky.com"
}

resource "acme_certificate" "tls_mail" {
  account_key_pem = "${acme_registration.tls_mail.account_key_pem}"
  common_name     = "mail.${var.domain}"

  dns_challenge {
    provider = "cloudflare"

    config {
      CLOUDFLARE_EMAIL   = "jakob@odersky.com"
      CLOUDFLARE_API_KEY = "${var.secret_cloudflare_token}"
    }
  }
}

resource "hcloud_rdns" "rdns4" {
  server_id  = "${var.server_id}"
  ip_address = "${var.server_ipv4}"
  dns_ptr    = "mail.${var.domain}"
}

resource "hcloud_rdns" "rdns6" {
  server_id  = "${var.server_id}"
  ip_address = "${var.server_ipv6}"
  dns_ptr    = "mail.${var.domain}"
}

resource "cloudflare_record" "record_a" {
  type   = "A"
  domain = "${var.domain}"
  name   = "mail"
  value  = "${var.server_ipv4}"
}

resource "cloudflare_record" "record_aaaa" {
  type   = "AAAA"
  domain = "${var.domain}"
  name   = "mail"
  value  = "${var.server_ipv6}"
}

resource "cloudflare_record" "record_mx" {
  type   = "MX"
  domain = "${var.domain}"
  name   = "@"
  value  = "mail.${var.domain}"
}

resource "cloudflare_record" "record_spf" {
  type   = "TXT"
  domain = "${var.domain}"
  name   = "@"
  value  = "v=spf1 a mx -all"
}

resource "cloudflare_record" "record_dmarc" {
  type   = "TXT"
  domain = "${var.domain}"
  name   = "_dmarc"
  value  = "v=DMARC1; p=quarantine; rua=mailto:postmaster@${var.domain}"
}

resource "tls_private_key" "dkim" {
  algorithm = "RSA"
}

resource "cloudflare_record" "record_dkim_txt" {
  type   = "TXT"
  domain = "${var.domain}"
  name   = "mail._domainkey"
  value  = "v=DKIM1; k=rsa; p=${replace("${tls_private_key.dkim.public_key_pem}","/-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\n/","")};"
}

resource "null_resource" "config" {
  triggers {
    server_id        = "${var.server_id}"
    domain           = "${var.domain}"
    dkim_private_key = "${tls_private_key.dkim.private_key_pem}"
    mail_key         = "${acme_certificate.tls_mail.private_key_pem}"
    mail_cert        = "${acme_certificate.tls_mail.certificate_pem}"
  }

  connection {
    host = "${var.server_ipv4}"
  }

  provisioner "remote-exec" {
    inline = ["DEBIAN_FRONTEND=noninteractive apt-get install --yes postfix opendkim bsd-mailx dovecot-core dovecot-imapd"]
  }

  provisioner "file" {
    content     = "${acme_certificate.tls_mail.private_key_pem}"
    destination = "/etc/ssl/private/mail.key.pem"
  }

  provisioner "file" {
    content     = "${acme_certificate.tls_mail.certificate_pem}"
    destination = "/etc/ssl/mail.cert.pem"
  }

  provisioner "file" {
    content     = "${var.domain}\n"
    destination = "/etc/mailname"
  }

  provisioner "file" {
    source      = "${path.module}/postfix-master.cf"
    destination = "/etc/postfix/master.cf"
  }

  provisioner "file" {
    content = <<EOF
myhostname = mail.${var.domain}
myorigin = /etc/mailname
mydestination = $myhostname, ${var.domain}, localhost.localdomain, localhost

smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/mail.cert.pem
smtpd_tls_key_file=/etc/ssl/private/mail.key.pem
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:$${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:$${data_directory}/smtp_scache

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all
#home_mailbox = mail/

smtpd_milters = inet:127.0.0.1:8891
non_smtpd_milters = inet:127.0.0.1:8891
EOF

    destination = "/etc/postfix/main.cf"
  }

  provisioner "file" {
    content     = "${tls_private_key.dkim.private_key_pem}"
    destination = "/etc/dkimkeys/dkim.key"
  }

  provisioner "file" {
    content = <<EOF
Syslog			yes
UMask			007
Domain			${var.domain}
KeyFile			/etc/dkimkeys/dkim.key
# on Debian, directory permissions of /etc/dkimkeys already restrict access
RequireSafeKeys         false
Selector		mail
Canonicalization	relaxed/simple
Mode			s
Socket			inet:8891@127.0.0.1
PidFile                 /var/run/opendkim/opendkim.pid
OversignHeaders		From
TrustAnchorFile         /usr/share/dns/root.key
UserID                  opendkim
EOF

    destination = "/etc/opendkim.conf"
  }

  provisioner "file" {
    content = <<EOF
disable_plaintext_auth = no
mail_privileged_group = mail
mail_location = mbox:~/mail:INBOX=/var/mail/%u
userdb {
  driver = passwd
}
passdb {
  driver = passwd-file
  args = scheme=sha256-crypt username_format=%n /etc/imap.passwd
}
protocols = " imap"

service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0660
    user = postfix
  }
}
ssl=required
ssl_cert = </etc/ssl/mail.cert.pem
ssl_key = </etc/ssl/private/mail.key.pem
EOF

    destination = "/etc/dovecot/dovecot.conf"
  }

  provisioner "file" {
    # content generated with
    # echo "root:$(doveadm pw -s sha256-crypt -p "$(pass infra/root@crashbox.io)")"
    content = "root:{SHA256-CRYPT}$5$Yymf6C.k4LgUaNla$UqKwSSIewxCyLV72zXNjfVI2s3xdicXmgCM99BwxWeB"

    destination = "/etc/imap.passwd"
  }

  provisioner "remote-exec" {
    inline = [
      "usermod --append --groups ssl-cert postfix",
      "usermod --append --groups ssl-cert dovecot",
      "systemctl restart opendkim.service postfix.service dovecot.service",
      "ufw allow 25",
      "ufw allow 587",
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "DEBIAN_FRONTEND=noninteractive apt-get purge --yes postfix opendkim dovecot-core dovecot-imapd",
      "rm -rf /etc/dkimkey/dkim.key",
      "rm -f /etc/ssl/mail.cert.pem",
      "rm -f /etc/ssl/private/mail.key.pem",
      "ufw delete allow 25",
      "ufw delete allow 587",
    ]
  }
}
