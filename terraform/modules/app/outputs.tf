output "alb_dns_name" {
  description = "The URL of the Load Balancer to access the backend"
  value       = aws_alb.main.dns_name
}

output "s3_bucket_name" {
  description = "The name of the frontend bucket"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_domain" {
  description = "The CloudFront URL for the frontend"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "redis_endpoint" {
  description = "The connection endpoint for Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}