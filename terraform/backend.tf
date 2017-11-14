terraform {
  backend "s3" {
    bucket = "ketouem-terraform-state"
    key    = "ketouem.com/terraform.tfstate"
    region = "eu-west-1"
  }
}
