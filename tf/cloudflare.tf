variable "cf_email" {
  type = string
  description = "API account email"
}

variable "cf_api_key" {
  type = string
  sensitive = true
  description = "API access token"
}

variable "cf_zone_name" {
  type = string
  description = "DNS zone domain name"
}

variable "cf_zone_id" {
  type = string
  description = "DNS zone id"
}

variable "cf_account_id" {
  type = string
  description = "Account id"
}

provider "cloudflare" {
  api_key = var.cf_api_key
  email = var.cf_email
}

resource "cloudflare_record" "b2_proxy" {
  zone_id = var.cf_zone_id
  name    = "@"
  type    = "CNAME"
  value   = local.b2_cname_target
  proxied = true
}

resource "cloudflare_worker_script" "cf_b2_public" {
  account_id = var.cf_account_id
  name    = "b2-${var.b2_bucket_name}"
  content = file("cf-b2-public.js")

  plain_text_binding {
    name = "B2_BUCKET_NAME"
    text = var.b2_bucket_name
  }
}

resource "cloudflare_worker_route" "cf_b2_public" {
  zone_id     = var.cf_zone_id
  pattern     = "${var.cf_zone_name}/*"
  script_name = cloudflare_worker_script.cf_b2_public.name
}
