# CloudWatch Log Group for Backend Logs
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/starttech-backend-v3"
  retention_in_days = 7
}

# IAM Role for EC2/ECS Instances
resource "aws_iam_role" "ecs_agent" {
  name = "starttech-ecs-agent-v3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Policy to allow writing to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_cw_logs" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}