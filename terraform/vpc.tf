resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  lifecycle {
    # If the VPC is already there, this tells Terraform:
    # "Don't try to change anything about it if you ever manage to track it."
    ignore_changes = all
  }
}