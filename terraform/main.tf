# 1. Networking Module (Updated for Multi-AZ)
module "networking" {
  source              = "./modules/networking"
  vpc_cidr            = "10.0.0.0/16"
  # Provide a list if your module supports it, or ensure the module 
  # creates at least two subnets internally.
  public_subnet_cidr = ["10.0.1.0/24", "10.0.2.0/24"] 
}

# 2. S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "starttech-frontend-latifah-${random_id.id.hex}"
}

resource "random_id" "id" { 
  byte_length = 4 
}

# 3. ECR Repository (Creates the URL needed for the App Module)
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
  # module.networking.public_subnet_ids should return a LIST of at least 2 IDs
  subnets         = module.networking.public_subnet_ids 
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  target_type = "ip" # <--- MUST be "ip" for Fargate
  name        = "starttech-backend-tg-v5"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id



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
  vpc_id = module.networking.vpc_id
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
  vpc_id = module.networking.vpc_id

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

# 6. Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis-v5"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
}

# 7. App Module (Updated to pass all required data)
module "app" {
  source       = "./modules/app" 
  vpc_id       = module.networking.vpc_id
  subnet_ids   = module.networking.public_subnet_ids
  
  # This fixes the "ecr_repo_url is required" error
  ecr_repo_url = aws_ecr_repository.backend.repository_url
  
  # These link the Load Balancer and Security Groups created above to your container
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  security_group_id = aws_security_group.backend_sg.id
}