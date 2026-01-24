output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = [aws_subnet.public.id] # Wrapping in brackets makes it a list
  description = "The IDs of the public subnets"
}