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
  iam_instance_profile { 
    name = aws_iam_instance_profile.ecs_profile.name 
  }
}

# 7. Auto Scaling Group
resource "aws_autoscaling_group" "backend_asg" {
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "ecs-instance-profile-${random_id.id.hex}"
  role = aws_iam_role.ecs_agent.name
}