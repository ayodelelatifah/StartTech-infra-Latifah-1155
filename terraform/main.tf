# 1. NETWORK LOOKUP (Default VPC)
data "aws_vpc" "selected" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# 2. ECR REPOSITORY
resource "aws_ecr_repository" "backend" {
  name                 = "starttech-backend-final"
  image_tag_mutability = "MUTABLE"
  force_delete         = true 

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 3. SECURITY GROUPS
# ALB Security Group (Internet -> ALB)
resource "aws_security_group" "alb_sg" {
  name        = "starttech-alb-sg-final"
  vpc_id      = data.aws_vpc.selected.id

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

# Backend Security Group (ALB -> ECS Tasks)
resource "aws_security_group" "backend_sg" {
  name        = "starttech-backend-sg-final"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port       = 8080 
    to_port         = 8080
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

# Redis Security Group (ECS Tasks -> Redis)
resource "aws_security_group" "redis_sg" {
  name        = "starttech-redis-sg-final"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. LOAD BALANCER & TARGET GROUP
resource "aws_alb" "main" {
  name            = "starttech-alb-final"
  subnets         = data.aws_subnets.all.ids 
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "starttech-tg-final"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

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

# 5. APP MODULE
module "app" {
  source            = "./modules/app"
  vpc_id            = data.aws_vpc.selected.id
  subnet_ids        = data.aws_subnets.all.ids
  ecr_repo_url      = aws_ecr_repository.backend.repository_url
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  security_group_id = aws_security_group.backend_sg.id
}

# 6. S3 FRONTEND
resource "random_id" "id" {
  byte_length = 4
}

resource "aws_s3_bucket" "frontend" {
  bucket = "starttech-frontend-latifah-${random_id.id.hex}"
}

# 7. REDIS (ELASTICACHE)
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "starttech-redis-subnets"
  subnet_ids = data.aws_subnets.all.ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}

# 8. OUTPUTS
output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
  description = "Copy this URL for your GitHub Actions"
}

output "alb_dns_name" {
  value = aws_alb.main.dns_name
  description = "The URL to access your backend"
}