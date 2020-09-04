terraform {
  required_version = "~> 0.13.2"
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}
