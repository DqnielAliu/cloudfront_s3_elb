variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_caching" {
  description = "Disable caching during testing for convenience."
  type        = bool
  default     = false
}

/* Created a toggle for the load balancer origin as load balancer cost some $$$. */
variable "enable_load_balancer_origin" {
  description = "Toggle the creation of the load balancer origin and it's associated resources."
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Toggle the creation of an S3 bucket to store standard/access logs."
  type        = bool
  default     = false
}

#####################
## ACM & Route53 (Optional)
#####################
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate. The certificate must be in the US East (N. Virginia) Region (us-east-1)."
  type        = string
  default     = null
}

variable "hosted_zone_name" {
  description = "Hosted zone name. Obtain this from your Route53 service."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Hosted zone ID. Obtain this from your Route53 service."
  type        = string
  default     = ""
  # default     = "Z0393220AHXX95SI31LM"
}