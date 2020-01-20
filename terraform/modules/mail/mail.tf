variable "tld" {}

# Mail Records
resource "digitalocean_record" "hushmail-1" {
  domain = var.tld
  type = "MX"
  name = "@"
  value = "plsmtp2.hushmail.com."
  priority = "10"
}

resource "digitalocean_record" "hushmail-2" {
  domain = var.tld
  type = "MX"
  name = "@"
  value = "plsmtp1.hushmail.com."
  priority = "10"
}
