
# Retrieve the existing VPC
data "aws_vpc" "main" {
  id = "vpc-0ee304c59e546ce25"  # Replace with your VPC ID
}

# Public Subnet in the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # Adjusted to avoid conflict
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

# Private Subnet in the VPC
resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # Adjusted to avoid conflict
  availability_zone       = "eu-north-1a"
  tags = {
    Name = "PrivateSubnet"
  }
}

# Check if an existing Internet Gateway exists for the given VPC
data "aws_internet_gateway" "existing_gw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Create a new Internet Gateway if none exists
resource "aws_internet_gateway" "gw" {
  count   = data.aws_internet_gateway.existing_gw.id == "" ? 1 : 0
  vpc_id  = data.aws_vpc.main.id
}

# Create NAT Gateway in the Public Subnet, using an existing Elastic IP
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "eipalloc-0f31490b059b9694f"  # Replace with your Elastic IP allocation ID
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.gw]  # Ensure IGW is created first
}

# Public Route Table with IGW
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing_gw.id != "" ? data.aws_internet_gateway.existing_gw.id : aws_internet_gateway.gw[0].id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Public Route Table with the Public Subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table with NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group allowing HTTP, HTTPS, and SSH
resource "aws_security_group" "allow_http_https_ssh" {
  vpc_id = data.aws_vpc.main.id

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

# Launch EC2 instance in Public Subnet
resource "aws_instance" "my_ec2" {
  ami           = "ami-08eb150f611ca277f"  # Replace with Amazon Linux 2 AMI for your region
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_http_https_ssh.id]

  tags = {
    Name = "csy_instance"
  }
}
