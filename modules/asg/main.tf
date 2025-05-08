data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-lt-"
  image_id               = var.ami_id != null ? var.ami_id : data.aws_ami.amazon-linux-2.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.default.id]

  key_name  = var.key_name
  user_data = var.user_data != null ? var.user_data : filebase64("./scripts/user-data.sh")

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  metadata_options {
    # Whether the metadata service is available
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Spot Instance Configuration (Optional)
  dynamic "instance_market_options" {
    for_each = var.enable_spot_instances ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price                      = var.spot_max_price
        instance_interruption_behavior = var.spot_instance_interruption_behavior
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "terraform-simple-ec2-origin"
      }
    )
  }
}

resource "aws_autoscaling_group" "this" {
  name                = var.name
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  # health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  target_group_arns         = ["${aws_lb_target_group.this.arn}"]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Instance IAM Role
resource "aws_iam_instance_profile" "this" {
  name = "terraform_simplei_instance_profile"
  role = aws_iam_role.instance_service.name
}

data "aws_iam_policy_document" "ec2_service" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "instance_service" {
  name               = "instance-srv-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_service.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance_service.name
}

# Application Loadbalancer
resource "aws_lb" "this" {
  name                             = var.name
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = var.subnet_ids
  security_groups                  = [aws_security_group.default.id]
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  ip_address_type                  = "ipv4"
  enable_deletion_protection       = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb"
    }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-listner"
    }
  )
}

resource "aws_lb_target_group" "this" {
  name                          = var.name
  port                          = 80
  protocol                      = "HTTP"
  target_type                   = var.target_type
  vpc_id                        = var.vpc_id
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = 80
    protocol            = "HTTP"
    timeout             = 10
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-tg"
    }
  )
}

# Security Group
resource "aws_security_group" "default" {
  name        = "default access"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-default-sg"
      description = "Allow web traffic"
    }
  )
}

# Ingress Rule: Allow HTTP Traffic
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  description       = "Allows HTTP ingress for IPv4 all IPs"
  security_group_id = aws_security_group.default.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Ingress Rule: Allow HTTPS Traffic
resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  description       = "Allows HTTPS ingress for IPv4 all IPs"
  security_group_id = aws_security_group.default.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Ingress Rule: Allow SSH Traffic
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  description       = "Allows SSH ingress for IPv4 all IPs"
  security_group_id = aws_security_group.default.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Egress Rule: Allow All Outbound Traffic
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  description       = "Allows egress for IPv4 to internet"
  security_group_id = aws_security_group.default.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}