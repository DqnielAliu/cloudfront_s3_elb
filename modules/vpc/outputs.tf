output "vpc_id" {
  value = aws_vpc.this.id
}

output "sg_id" {
  value = aws_security_group.ec2.id
}

output "list_of_subnet_ids" {
  value = aws_subnet.public[*].id
}
