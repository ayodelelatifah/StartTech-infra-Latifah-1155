# Root main.tf 
# Note: Terraform and Provider blocks are now only in provider.tf

# This block pulls in the code you wrote in modules/networking
module "networking" {
  source             = "./modules/networking"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.1.0.0/24"
}

# This block pulls in the code you wrote in modules/app
module "app" {
  source     = "./modules/app"
  vpc_id     = module.networking.vpc_id
  # Updated to plural 'subnet_ids' to match your variables.tf fix
  subnet_ids = module.networking.public_subnet_ids 
}