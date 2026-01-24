output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  # We must use public_1 and public_2 because 'public' no longer exists
  value = [aws_subnet.public.id, aws_subnet.public_2.id]
}