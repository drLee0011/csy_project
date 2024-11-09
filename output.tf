# Output the VPC ID, Subnet IDs, and EC2 Instance ID
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "ec2_instance_id" {
  value = aws_instance.my_ec2.id
}