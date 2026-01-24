# 1. Launch Template: Defines the server setup
resource "aws_launch_template" "backend" {
  name_prefix   = "starttech-backend-"
  image_id      = "ami-0c101f26f147fa7fd" # Amazon Linux 2023
  instance_type = "t3.micro"

  # The script that runs on startup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              # Login to ECR and run the Go container
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.ecr_repo_url}
              docker run -d -p 80:8080 ${var.ecr_repo_url}:latest
              EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.backend_sg_id]
  }
}

# 2. Auto Scaling Group: Manages the number of servers
resource "aws_autoscaling_group" "backend_asg" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  target_group_arns   = [var.target_group_arn] # Links to your Load Balancer
  vpc_zone_identifier = var.public_subnets

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
}

# Create the Role
resource "aws_iam_role" "backend_role" {
  name = "starttech-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

# Attach the "Read Only" permission for ECR
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# This "Profile" is what actually gets attached to the EC2 instance
resource "aws_iam_instance_profile" "backend_profile" {
  name = "starttech-backend-profile"
  role = aws_iam_role.backend_role.name
}

