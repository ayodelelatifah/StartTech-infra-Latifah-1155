# 1. We look up the VPC that ALREADY exists from your failed runs
data "aws_vpc" "selected" {
  id = "vpc-0357a5db33ec39634" 
}

# 2. We look up the subnets inside that VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# 3. We use the ECR repo you ALREADY created in the v12 run
data "aws_ecr_repository" "backend" {
  name = "starttech-backend-repo-v12"
}

# 4. We ONLY create the App/Service part
module "app" {
  source            = "./modules/app" 
  vpc_id            = data.aws_vpc.selected.id
  subnet_ids        = data.aws_subnets.all.ids
  ecr_repo_url      = data.aws_ecr_repository.backend.repository_url
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  security_group_id = aws_security_group.backend_sg.id
}

# 5. Unique Load Balancer for THIS run
resource "aws_alb" "main" {
  name            = "alb-final-attempt"
  subnets         = data.aws_subnets.all.ids 
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  target_type = "ip"
  name        = "tg-final-attempt"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
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

# 6. Fresh Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "sg-alb-final"
  vpc_id = data.aws_vpc.selected.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name   = "sg-backend-final"
  vpc_id = data.aws_vpc.selected.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}