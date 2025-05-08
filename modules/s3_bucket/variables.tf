variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
  default     = {}
}

variable "distribution_arn" {
  type = string
}

variable "enable_logging" {
  type = bool
}