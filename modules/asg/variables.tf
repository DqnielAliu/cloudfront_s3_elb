
#####################
## General Naming and Tagging
#####################
variable "name" {
  type        = string
  description = "A unique name prefix for all resources"
  default     = "my-app"
}

variable "environment" {
  type        = string
  description = "Environment of the deployment (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
  default = {
    Project     = "Simple-App"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# VPC Configuration
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy into"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs for the Auto Scaling Group"
}

# variable "lb_subnet" {
#   type        = list(string)
#   description = "A list of subnet IDs for the Load Balancer"
# }

#####################
## Auto Scaling Group Configuration
#####################
variable "min_size" {
  type        = number
  description = "Minimum number of instances in the Auto Scaling Group"
  default     = 0
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in the Auto Scaling Group"
  default     = 2
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances in the Auto Scaling Group"
  default     = 1
}

variable "health_check_grace_period" {
  type        = number
  description = "Time (in seconds) after instance comes into service before ELB health checks begin"
  default     = 300
}

variable "target_group_arns" {
  type        = list(string)
  description = "A list of target group ARNs to attach to the Auto Scaling Group"
  default     = []
}

#####################
## Launch Template Configuration
#####################
variable "ami_id" {
  type        = string
  description = "The ID of the AMI to use for the EC2 instances (optional, will use latest Amazon Linux 2 if not provided)"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for the EC2 instances"
  default     = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "The name of the EC2 Key Pair to allow SSH access"
  default     = ""
}

variable "security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs to attach to the EC2 instances (optional, will create a default SG if not provided)"
  default     = []
}

variable "user_data" {
  type        = string
  description = "Path to the user data script to run on instance launch (optional)"
  default     = ""
}

#####################
## Spot Instance Configuration
#####################
variable "enable_spot_instances" {
  type        = bool
  description = "Enable the use of Spot Instances"
  default     = true
}

variable "spot_max_price" {
  type        = string
  description = "The maximum price (in USD) you are willing to pay for Spot Instances"
  default     = "0.0045"
  nullable    = false
  sensitive   = true # Consider if the default is sensitive
}

variable "spot_instance_interruption_behavior" {
  type        = string
  description = "The behavior when a Spot Instance is to be interrupted ('terminate' or 'stop')"
  default     = "terminate"
  validation {
    condition     = contains(["terminate", "stop"], lower(var.spot_instance_interruption_behavior))
    error_message = "spot_instance_interruption_behavior must be either 'terminate' or 'stop'."
  }
}

#####################
## Load Balancer Configuration
#####################
variable "target_type" {
  type        = string
  description = "The target type for the load balancer ('instance' or 'ip')"
  default     = "instance"
  validation {
    condition     = contains(["instance", "ip"], lower(var.target_type))
    error_message = "target_type must be either 'instance' or 'ip'."
  }
}

variable "health_check_path" {
  type        = string
  description = "The path for the target group health check"
  default     = "/"
}

# variable "container_port" { # Consider if this is always 80 or needs to be configurable
#   type        = number
#   description = "The port the application listens on within the container (if using container targets)"
#   default     = 80
# }

variable "enable_stickness" {
  type        = bool
  description = "Enable load balancer stickiness"
  default     = false
}