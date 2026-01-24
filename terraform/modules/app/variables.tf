variable "vpc_id" {
  type        = string
  description = "The ID of the VPC from the networking module"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The list of public subnets from the networking module"
}

variable "ecr_repo_url" {
  type        = string
  description = "The URL of the ECR repository created in the root"
}

variable "target_group_arn" {
  type        = string
  description = "The ARN of the Load Balancer target group created in the root"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the backend security group created in the root"
}