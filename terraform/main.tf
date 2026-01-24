# 1. NETWORKING - Commented out to avoid "Already Exists" conflicts
# module "networking" {
#   source = "./modules/networking"
# }

# 2. S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "starttech-frontend-latifah-${random_id.id.hex}"
}

resource "random_id" "id" { 
  byte_length = 4 
}

# 3. ECR Repository
resource "aws_ecr_repository" "backend" {
  name                 = "starttech-backend-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 4. Infrastructure: Load Balancer & Routing
resource "aws_alb" "main" {
  name            = "starttech-alb-v5"
  # These are the subnets from your existing VPC
  subnets         = ["subnet-07080b06b0d990666", "subnet-08f32c18096f30419"] 
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  target_type = "ip"
  name        = "starttech-backend-tg-v5"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0357a5db33ec39634"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# 5. Security Groups
resource "aws_security_group" "alb_sg" {
  vpc_id = "vpc-0357a5db33ec39634"
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
  vpc_id = "vpc-0357a5db33ec39634"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 6. App Module - Manually connected to your VPC and Subnets
module "app" {
  source            = "./modules/app" 
  vpc_id            = "vpc-0357a5db33ec39634"
  subnet_ids        = ["subnet-07080b06b0d990666", "subnet-08f32c18096f30419"]
  ecr_repo_url      = aws_ecr_repository.backend.repository_url
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  security_group_id = aws_security_group.backend_sg.id
}

# 7. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_log" {
  # New name to ensure no "AlreadyExists" error
  name              = "/aws/lambda/starttech-api-log-success" 
  retention_in_days = 7
}