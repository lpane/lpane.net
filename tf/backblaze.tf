variable "b2_application_key" {
  type = string
  sensitive = true
  description = "Master application key"
}

variable "b2_application_key_id" {
  type = string
  sensitive = true
  description = "Master application key ID"
}

variable "b2_bucket_name" {
  type = string
  description = "Bucket name"
}

provider "b2" {
  application_key = var.b2_application_key
  application_key_id = var.b2_application_key_id
}

resource "b2_application_key" "assets_bucket_key" {
  key_name = var.b2_bucket_name
  bucket_id = b2_bucket.static_assets.id
  capabilities = ["listFiles", "listBuckets", "writeFiles", "deleteFiles"]
}

resource "b2_bucket" "static_assets" {
  bucket_name = var.b2_bucket_name
  bucket_type = "allPublic"
}

data "b2_account_info" "b2_account" {}

locals {
  // B2 public download URL target
  b2_cname_target = trimsuffix(replace(data.b2_account_info.b2_account.download_url, "https://", ""), "/")
}

output "b2" {
  value = {
    applicationKeyId = b2_application_key.assets_bucket_key.application_key_id
    applicationKey = b2_application_key.assets_bucket_key.application_key
  }
  sensitive = true
}
