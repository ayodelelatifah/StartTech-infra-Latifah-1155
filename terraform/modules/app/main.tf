# 1. S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "starttech-frontend-latifah-${random_id.id.hex}"
}

resource "random_id" "id" { 
  byte_length = 4 
}

# 2. Application Load Balancer (ALB)
resource "aws_alb" "main" {
  name            = "starttech-alb-v5"
  subnets         = var.subnet_ids # Note: Using a list for High Availability
  security_groups = [aws_security_group.alb_sg.id]
}
# 2a. Target Group (The "Destination" for the ALB)
resource "aws_lb_target_group" "backend_tg" {
  name     = "starttech-backend-tg-v5"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health" # Must match your Go code!
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# 2b. ALB Listener (The "Ear" that listens for traffic)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# 3. Security Group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name   = "starttech-backend-sg-v5"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only allow the ALB in
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis-v5"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "redis-subnets-v5"
  subnet_ids = var.subnet_ids
}

# 5. CloudFront Distribution (Fixed Syntax)
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-Frontend"
  }
  
  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 6. Launch Template for ECS/Backend
resource "aws_launch_template" "backend" {
  name_prefix   = "starttech-backend-"
  image_id      = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"

  # We use this block to attach the security group and public IP
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.backend_sg.id]
    device_index                = 0 # Added to satisfy provider requirements
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_profile.name
  }

user_data = base64encode(<<-EOF
    #!/bin/bash
    # 1. Update and Install Docker
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # 2. Login to ECR (Using the IAM Role attached to the instance)
    # Note: Replace us-east-1 with your region if different
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.ecr_repo_url}

    # 3. Pull and Run the Container
    docker pull ${var.ecr_repo_url}:latest
    docker run -d -p 80:8080 ${var.ecr_repo_url}:latest
  EOF
  )
}

# 7. Auto Scaling Group
resource "aws_autoscaling_group" "backend_asg" {
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "ecs-instance-profile-${random_id.id.hex}"
  role = aws_iam_role.ecs_agent.name
}
# Create the ECR repository
resource "aws_ecr_repository" "backend" {
  name                 = "starttech-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "app" {
  source       = "./modules/app"
  vpc_id       = module.networking.vpc_id
  subnet_ids   = module.networking.public_subnet_ids
  
  # This dynamic reference fixes the "required argument" error
  ecr_repo_url = aws_ecr_repository.backend.repository_url 
}