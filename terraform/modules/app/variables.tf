variable "vpc_id" {
  description = "The ID of the VPC from networking module"
}

variable "subnet_ids" { # Change this to plural
  type        = list(string) # Add this type
  description = "The list of public subnets from networking module"
}