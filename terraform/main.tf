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
  #server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

################################################################################

resource "hcloud_ssh_key" "root" {
  name       = "root"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

module "vps" {
  source       = "./stdvps"
  location     = "nbg1"
  ssh_key_name = "${hcloud_ssh_key.root.name}"
  volume_name = "master"
}

module "roles" {
  source                  = "./role"
  secret_cloudflare_token = "${var.secret_cloudflare_token}"
  host                    = "${module.vps.fqdn}"
  id                      = "${module.vps.id}"
  roles                   = ["ip", "git"]
}

output "vps_address" {
  value = "${module.vps.fqdn}"
}

output "vps_roles" {
  value = "${join(" ", module.roles.roles)}"
}
