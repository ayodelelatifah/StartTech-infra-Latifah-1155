output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "The name of the ECS cluster"
}

output "ecs_service_name" {
  value       = aws_ecs_service.main.name
  description = "The name of the ECS service"
}