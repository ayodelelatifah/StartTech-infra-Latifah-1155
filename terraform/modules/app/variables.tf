variable "vpc_id" {
  type        = string
  description = "The ID of the VPC from networking module"
}

variable "subnet_ids" { # Note the 's' for plural
  type        = list(string) # This MUST be list(string)
  description = "The list of public subnets from networking module"
}