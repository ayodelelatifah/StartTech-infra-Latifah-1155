# 1. NEW NETWORK CREATION
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "starttech-vpc" }
}


resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "starttech-subnet-a" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "starttech-subnet-b" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "starttech-igw" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt.id
}

# 2. ECR REPOSITORY
resource "aws_ecr_repository" "backend" {
  name                 = "starttech-backend-v2"
  image_tag_mutability = "MUTABLE"
  force_delete         = true 
  image_scanning_configuration { scan_on_push = true }
}

# 3. SECURITY GROUPS
resource "aws_security_group" "alb_sg" {
  name   = "starttech-alb-sg-final"
  vpc_id = aws_vpc.main.id
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
  name   = "starttech-backend-sg-final"
  vpc_id = aws_vpc.main.id
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

resource "aws_security_group" "redis_sg" {
  name   = "starttech-redis-sg-final"
  vpc_id = aws_vpc.main.id
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

# 4. LOAD BALANCER
resource "aws_alb" "main" {
  name            = "starttech-alb-v2"
  subnets         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "starttech-tg-v2"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/health" }
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
  vpc_id            = aws_vpc.main.id
  subnet_ids        = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  ecr_repo_url      = aws_ecr_repository.backend.repository_url
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  security_group_id = aws_security_group.backend_sg.id
}

# 6. S3 FRONTEND
resource "random_id" "id" { byte_length = 4 }
resource "aws_s3_bucket" "frontend" {
  bucket = "starttech-frontend-latifah-${random_id.id.hex}"
}

# 7. REDIS
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "starttech-redis-subnets-v3"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}


resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis-v2"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}