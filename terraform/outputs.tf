output "backend_url" {
  value = module.app.alb_dns_name
}

output "frontend_url" {
  value = module.app.cloudfront_domain
}