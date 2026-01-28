# 1. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "starttech-cluster"
}

# 2. CloudWatch Log Group (Required for the logConfiguration below)
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/starttech-backend-v2"
  retention_in_days = 7
}

# 3. ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "starttech-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.ecr_repo_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080 # FIXED: Matches root Target Group
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/starttech-backend"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 4. ECS Service
resource "aws_ecs_service" "main" {
  name            = "starttech-service-v2"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = 8080 # FIXED: Matches Task Definition
  }
}

# 5. IAM Role for ECS Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "starttech-ecs-task-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}