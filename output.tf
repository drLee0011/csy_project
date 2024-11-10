output "vpc_id" {
  value = data.aws_vpc.main.id  # Corrected to reference the data source
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

output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.my_ec2.public_ip
}

