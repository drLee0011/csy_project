# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # CIDR block for the VPC
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "csy_vpc"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # CIDR block for the public subnet
  availability_zone       = "eu-north-1a"    # Specify availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"  # CIDR block for the private subnet
  availability_zone       = "eu-north-1a"    # Specify availability zone
  tags = {
    Name = "PrivateSubnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainInternetGateway"
  }
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Create a NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.gw]  # Ensure the IGW is created before the NAT Gateway
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate the Public Route Table with the Public Subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate the Private Route Table with the Private Subnet
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group to Allow HTTP/HTTPS and SSH
resource "aws_security_group" "allow_http_https_ssh" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AllowHTTPSSHTraffic"
  }
}

# Launch an EC2 instance in the Public Subnet
resource "aws_instance" "my_ec2" {
  ami           = "ami-08eb150f611ca277f"  # Replace with the latest Amazon Linux 2 AMI ID for your region
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_http_https_ssh.id]

  tags = {
    Name = "csy_instance"
  }
}

