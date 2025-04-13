output "vpc_id" {
  value = var.enable_load_balancer_origin ? module.vpc[0].vpc_id : "NA"
}

output "sg_id" {
  value = var.enable_load_balancer_origin ? module.vpc[0].sg_id : "NA"
}

output "list_of_subnet_ids" {
  value = var.enable_load_balancer_origin ? module.vpc[0].list_of_subnet_ids : []
}

output "CloudFront_Distribution_Domain_Name" {
  value = module.cloudfront.distribution_domain_name
}

output "S3_endpoint" {
  value = module.s3.s3_website_endpoint
}

output "aws_canonical_user_id" {
  value = module.s3.aws_canonical_user_id
}