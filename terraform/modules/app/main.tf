# 1. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "starttech-cluster"
}

# 2. ECS Task Definition
# This defines the "blueprint" for your container
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
      image     = "${var.ecr_repo_url}:latest" # Uses the variable passed from root
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/starttech-backend"
          "awslogs-region"        = "us-east-1" # Change to your region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 3. ECS Service
# This maintains the desired number of running instances
resource "aws_ecs_service" "main" {
  name            = "starttech-service"
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
    container_port   = 80
  }
}

# 4. IAM Role for ECS Execution
# This allows ECS to pull images from ECR and send logs to CloudWatch
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "starttech-ecs-task-execution-role"

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

# 5. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/starttech-backend"
  retention_in_days = 7
}