
resource "random_string" "name_suffix" {
  length  = 6
  special = false
  upper   = false
}

data "aws_canonical_user_id" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Logging Bucket
resource "aws_s3_bucket" "standard_logging" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = format("cloudfront-logs-%s", random_string.name_suffix.result)
}

resource "aws_s3_bucket_policy" "logging" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = aws_s3_bucket.standard_logging[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowCloudFrontServicePrincipal",
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.standard_logging[0].arn}/*"],
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Condition = {
          StringEquals = {
            "AWS:SourceArn"     = var.distribution_arn
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "aws:SourceAccount" = data.aws_caller_identity.current.id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "standard_logging" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = aws_s3_bucket.standard_logging[0].id

  rule {
    object_ownership = "BucketOwnerPreferred" # BucketOwnerPreferred | ObjectWriter | BucketOwnerEnforced
  }
}

resource "aws_s3_bucket_acl" "standard_logging" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = aws_s3_bucket.standard_logging[0].id

  access_control_policy {
    grant {
      grantee {
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.standard_logging]
}

resource "aws_s3_bucket_logging" "website_logging" {
  count         = var.enable_cloudfront_logging ? 1 : 0
  bucket        = aws_s3_bucket.standard_logging[0].id
  target_bucket = aws_s3_bucket.main.id
  target_prefix = "log/${aws_s3_bucket.main.id}/"
}

# Main S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = format("terraform-cloudfront-%s", random_string.name_suffix.result)
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowCloudFrontServicePrincipal",
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.main.arn}/*"],
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.distribution_arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "default" {
  bucket = aws_s3_bucket.main.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "500.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "default" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Mapping of file extensions to MIME types
locals {
  html_files = fileset("${path.module}/objects", "**/*") # Match all files and directories
  mime_types = {
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "json" = "application/json",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "txt"  = "text/plain",
    "pdf"  = "application/pdf",
    "ico"  = "image/x-icon"
  }
}

# Upload all the files present under the folder to the S3 bucket with correct content types
resource "aws_s3_object" "upload_object" {
  for_each     = local.html_files #{ for file in local.html_files : file => file }
  bucket       = aws_s3_bucket.main.id
  key          = each.value
  source       = "${path.module}/objects/${each.value}"
  etag         = filemd5("${path.module}/objects/${each.value}")
  content_type = lookup(local.mime_types, element(tolist([regex("[^.]*$", each.value)]), 0), "binary/html")
}