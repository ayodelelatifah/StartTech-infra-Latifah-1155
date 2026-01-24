# Root main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# This block pulls in the code you wrote in modules/networking
module "networking" {
  source              = "./modules/networking"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
}

module "app" {
  source     = "./modules/app"
  vpc_id     = module.networking.vpc_id # Uses the output we created!
  subnet_id  = module.networking.public_subnet_id
}