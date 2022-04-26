# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# module "custom_default_vpc" {
#   source = "./modules/default-vpc"
# }

resource "aws_default_vpc" "default" {
  force_destroy = true
  tags = merge(var.default_tags, {
    name     = "aws_default_vpc"
    teardown = "enabled"
    },
  )
}




