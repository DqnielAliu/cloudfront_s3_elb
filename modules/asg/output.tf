output "origin_id" {
  value = aws_lb.this.dns_name
}

output "ALB_sg_id" {
  value = aws_security_group.default.id
}