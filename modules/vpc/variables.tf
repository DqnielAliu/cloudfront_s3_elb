variable "tags" {
  type    = map(any)
  default = {}
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "availability_zones" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}
