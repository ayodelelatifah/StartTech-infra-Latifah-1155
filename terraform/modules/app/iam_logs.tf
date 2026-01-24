# CloudWatch Log Group for Backend Logs
# resource "aws_cloudwatch_log_group" "api_log" {
#  name = "/aws/lambda/starttech-api-log"

#  lifecycle {
#    ignore_changes = all
#  }
# }
# resource "aws_cloudwatch_log_group" "backend_logs" {
#  name              = "/ecs/starttech-backend-v5"
#  retention_in_days = 7
# }

# IAM Role for EC2/ECS Instances
resource "aws_iam_role" "ecs_agent" {
  # FIX: Using name_prefix prevents "EntityAlreadyExists" errors
  name_prefix = "starttech-ecs-agent-" 

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

# Attach the standard Execution Role policy so ECS can pull images from ECR
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy to allow writing to CloudWatch
# resource "aws_iam_role_policy_attachment" "ecs_cw_logs" {
#  role       = aws_iam_role.ecs_agent.name
#  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
# }
