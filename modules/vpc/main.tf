### Creating a VPC also creates a default (main) route table and default (main) NACL
resource "aws_vpc" "this" {
  enable_dns_support   = true
  enable_dns_hostnames = true
  cidr_block           = var.vpc_cidr

  tags = merge(
    var.tags, {
      Name = "terraform_cloudfront_vpc"
    }
  )
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags, {
      Name = "terraform_cloudfront_igw"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(
    var.tags, {
      Name = "terraform_cloudfront_custom_routetable"
    },
  )
}

resource "aws_subnet" "public" {
  # If you do not explictly state which route table the subnet is associated with,
  # it will be associated with the default route table.
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = format("terraform_cloudfront_public_subnet_%s", (count.index + 1))
    },
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Security Group
resource "aws_security_group" "ec2" {
  name        = "terraform_cloudfront_ec2_securitygroup"
  description = "Allows all traffic from only ALB sg"
  vpc_id      = aws_vpc.this.id

  tags = merge(
    var.tags, {
      Name        = "terraform_cloudfront_sg"
      description = "Allow web traffic"
    }
  )
}

# Ingress Rule: Allow HTTP Traffic
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  description                  = "Allows only traffic from ALB"
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = var.alb_sg_id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}
# Egress Rule: Allow All Outbound Traffic
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  description       = "Allows egress for IPv4 to internet"
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}