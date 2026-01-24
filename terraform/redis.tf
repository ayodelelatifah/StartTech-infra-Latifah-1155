resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis-v5"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  lifecycle {
    prevent_destroy = true
  }
}