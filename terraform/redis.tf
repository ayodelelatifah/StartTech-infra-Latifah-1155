resource "aws_elasticache_cluster" "redis" {
  # ...same resource config...
  lifecycle {
    prevent_destroy = true
  }
}