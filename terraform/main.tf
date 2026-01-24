# 1. DYNAMIC LOOKUP - This finds your existing AWS infra automatically
data "aws_vpc" "selected" {
  id = "vpc-0357a5db33ec39634" # Your verified VPC ID from the logs
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# 2. S3 Bucket for Frontend (Using a fresh v9 name)
resource "aws_s3_bucket" "frontend" {
  bucket = "starttech-frontend-latifah-v9-${random_id.id.hex}"
}

resource "random_id" "id" { 
  byte_length = 4 
}

# 3. ECR Repository
resource "aws_ecr_repository" "backend" {
  name                 = "starttech-backend-repo-v9"
  image_tag_mutability = "MUTABLE"
}

# 4. Infrastructure: Load Balancer (Using dynamic subnets)
resource "aws_alb" "main" {
  name            = "starttech-alb-v9"
  subnets         = data.aws_subnets.all.ids 
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  target_type = "ip"
  name        = "starttech-tg-v9"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id

  health_check {
    path = "/health"
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
  name   = "starttech-alb-sg-v9"
  vpc_id = data.aws_vpc.selected.id
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
  name   = "starttech-backend-sg-v9"
  vpc_id = data.aws_vpc.selected.id
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

# 6. App Module (Plugged into dynamic IDs)
module "app" {
  source            = "./modules/app" 
  vpc_id            = data.aws_vpc.selected.id
  subnet_ids        = data.aws_subnets.all.ids
  ecr_repo_url      = aws_ecr_repository.backend.repository_url
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  security_group_id = aws_security_group.backend_sg.id
}

# 7. CloudWatch Log Group (Fresh names to bypass "AlreadyExists")
resource "aws_cloudwatch_log_group" "api_log_v9" {
  name              = "/aws/lambda/starttech-api-v9" 
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend_logs_v9" {
  name              = "/ecs/starttech-backend-v9"
  retention_in_days = 7
}