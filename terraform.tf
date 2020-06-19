terraform {
  required_version = "> 0.12.0"
  required_providers {
    aws = "~> 2.62"
  }
  backend "s3" {
    bucket  = "dcbear-engineering-dev-tfstate"
    key     = "tfstates/dfemo-app-vpcs"
    region  = "us-east-2"
    encrypt = true
  }
}

provider "aws" {
  alias   = "aws-east-2"
  region  = "us-east-2"
}

provider "aws" {
  alias   = "aws-west-2"
  region  = "us-west-2"
}

# provider "tls" {
#   version = "~> 2.1"
# }