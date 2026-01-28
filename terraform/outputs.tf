output "frontend_bucket_id" {
  value       = aws_s3_bucket.frontend.id
  description = "The name of the S3 bucket used for frontend hosting"
}

output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "The connection endpoint for the Redis cluster"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "The URL of the ECR repository for Docker images"
}

output "alb_dns_name" {
  value       = aws_alb.main.dns_name
  description = "The DNS name of the Load Balancer"
}

output "ecs_cluster_name" {
  value = module.app.cluster_name
}