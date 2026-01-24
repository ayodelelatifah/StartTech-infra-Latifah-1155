# Root main.tf 
# Duplicate terraform/provider blocks removed as they are in provider.tf

module "networking" {
  source             = "./modules/networking"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.1.0.0/24"
}

module "app" {
  source     = "./modules/app"
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids 
}
