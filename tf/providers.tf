terraform {
  required_providers {
    b2 = {
      source = "Backblaze/b2"
      version = ">= 0.8"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
