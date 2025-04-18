locals {
  default_tags = {
    description = "Demo project on cloudfront and static site"
    version     = "v0.1.3"
    Project     = "obelix"
  }
}

module "vpc" {
  count                     = var.enable_load_balancer_origin ? 1 : 0
  source                    = "./modules/vpc"
  vpc_cidr_block            = "10.1.0.0/16"
  list_of_subnet_cidr_range = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  list_of_azs               = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  default_tags              = local.default_tags
  ALB_sg_id                 = module.asg[0].ALB_sg_id
}

module "cloudfront" {
  source                      = "./modules/cloudfront"
  enable_load_balancer_origin = var.enable_load_balancer_origin
  asg_origin_id               = var.enable_load_balancer_origin ? module.asg[0].origin_id : ""
  s3_origin_id                = format("%s.s3.ap-southeast-1.amazonaws.com", module.s3.full_bucket_name)
  enable_caching              = var.enable_caching
  acm_certificate_arn         = var.acm_certificate_arn
  hosted_zone_name            = var.hosted_zone_name
  hosted_zone_id              = var.hosted_zone_id
  enable_cloudfront_logging   = var.enable_cloudfront_logging
  logging_bucket_name         = module.s3.logging_bucket_name
}

module "asg" {
  count              = var.enable_load_balancer_origin ? 1 : 0
  source             = "./modules/asg"
  subnet_ids         = module.vpc[0].list_of_subnet_ids
  tags               = local.default_tags
  security_group_ids = [module.vpc[0].sg_id]
  vpc_id             = module.vpc[0].vpc_id
  desired_capacity   = 1
}

module "s3" {
  source                    = "./modules/s3_bucket"
  distribution_arn          = module.cloudfront.distribution_arn
  enable_cloudfront_logging = var.enable_cloudfront_logging
}