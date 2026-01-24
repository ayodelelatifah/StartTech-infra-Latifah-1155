resource "aws_ecr_repository" "backend" {
  name                 = "starttech-backend" 
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Helpful for cleaning up during assessments

  image_scanning_configuration { scan_on_push = true }
  encryption_configuration     { encryption_type = "AES256" }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}