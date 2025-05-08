locals {
  tags = {
    description = "Demo project on cloudfront and static site"
    version     = "v0.1.4"
    Project     = "Mollusca"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

data "aws_availability_zones" "available" {}

module "vpc" {
  count  = var.enable_load_balancer_origin ? 1 : 0
  source = "./modules/vpc"

  vpc_cidr           = local.vpc_cidr
  public_subnet_cidr = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  availability_zones = local.azs
  alb_sg_id          = module.asg[0].alb_sg_id
  tags               = local.tags
}

module "cloudfront" {
  source = "./modules/cloudfront"

  enable_load_balancer_origin = var.enable_load_balancer_origin
  asg_origin_id               = var.enable_load_balancer_origin ? module.asg[0].origin_id : null
  s3_origin_id                = format("%s.s3.%s.amazonaws.com", module.s3.full_bucket_name, var.region)
  enable_caching              = var.enable_caching
  acm_certificate_arn         = var.acm_certificate_arn
  hosted_zone_name            = var.hosted_zone_name
  hosted_zone_id              = var.hosted_zone_id
  enable_logging              = var.enable_logging
  logging_bucket_name         = module.s3.logging_bucket_name
}

module "asg" {
  count  = var.enable_load_balancer_origin ? 1 : 0
  source = "./modules/asg"

  subnet_ids         = module.vpc[0].list_of_subnet_ids
  tags               = local.tags
  security_group_ids = [module.vpc[0].sg_id]
  vpc_id             = module.vpc[0].vpc_id
  desired_capacity   = 1
}

module "s3" {
  source = "./modules/s3_bucket"

  distribution_arn = module.cloudfront.distribution_arn
  enable_logging   = var.enable_logging
}