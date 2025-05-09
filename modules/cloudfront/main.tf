data "aws_caller_identity" "current" {}
resource "aws_cloudfront_distribution" "elb_s3_distribution" {
  comment             = "Created from Terraform"
  default_root_object = "index.html"
  enabled             = true

  default_cache_behavior {
    allowed_methods = var.method
    cached_methods  = var.method

    target_origin_id       = var.enable_load_balancer_origin ? var.asg_origin_id : var.s3_origin_id
    compress               = true
    cache_policy_id        = var.enable_caching ? var.Managed-CachingOptimized : var.Managed-CachingDisabled
    viewer_protocol_policy = "allow-all" # allow-all | https-only | redirect-to-https
    min_ttl                = 10
    default_ttl            = 10
    max_ttl                = 10
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.path_pattern
    content {
      allowed_methods        = var.method
      cache_policy_id        = var.enable_caching ? var.Managed-CachingOptimized : var.Managed-CachingDisabled
      cached_methods         = var.method
      compress               = true
      default_ttl            = 0
      max_ttl                = 0
      min_ttl                = 0
      path_pattern           = ordered_cache_behavior.value
      smooth_streaming       = false
      target_origin_id       = var.s3_origin_id
      trusted_key_groups     = []
      trusted_signers        = []
      viewer_protocol_policy = "allow-all"
    }
  }

  # Load Balancer Origin
  dynamic "origin" {
    for_each = var.enable_load_balancer_origin ? [1] : []

    content {
      connection_attempts = 3
      connection_timeout  = 10
      domain_name         = var.asg_origin_id
      origin_id           = var.asg_origin_id
      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "http-only" # http-only | https-only | match-viewer
        origin_read_timeout      = 30
        origin_ssl_protocols     = ["TLSv1.2"]
      }
    }
  }

  # S3 Origin
  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = var.s3_origin_id
    origin_id                = var.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.site_bucket.id
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 503
    response_code         = 503
    response_page_path    = "/maintenance.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  aliases = var.acm_certificate_arn != null ? ["www.${var.hosted_zone_name}"] : []

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null ? true : false
    /*
    minimum_protocol_version:
    Minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections. 
    Can only be set if cloudfront_default_certificate = false
    */
    minimum_protocol_version = "TLSv1" # "TLSv1.2_2021"

    acm_certificate_arn = var.acm_certificate_arn
    /*
    ssl_support_method:
    How you want CloudFront to serve HTTPS requests. 
    One of vip, sni-only, or static-ip. 
    Required if you specify acm_certificate_arn or iam_certificate_id
    */
    ssl_support_method = var.acm_certificate_arn == null ? "sni-only" : null
  }

  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []

    content {
      bucket          = "${var.logging_bucket_name}.s3.amazonaws.com"
      prefix          = "AWSLogs/${data.aws_caller_identity.current.account_id}/CloudFront/"
      include_cookies = false

    }
  }
}

resource "aws_cloudfront_origin_access_control" "site_bucket" {
  name                              = "host-static-website-OAC"
  description                       = "OAI for accessing S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# resource "aws_route53_record" "www" {
#   count   = var.acm_certificate_arn != null ? 1 : 0
#   zone_id = var.hosted_zone_id
#   name    = format("www.%s", var.hosted_zone_name)
#   type    = "CNAME"
#   ttl     = 60
#   records = [aws_cloudfront_distribution.elb_s3_distribution.domain_name]
# }
