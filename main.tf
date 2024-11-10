# Data resource to reference an existing VPC
data "aws_vpc" "main" {
  id = "vpc-0305c06746da14a3f"  # Replace with your existing VPC ID
}

# Check if an Internet Gateway exists in the VPC by using a data source
data "aws_internet_gateway" "existing_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Create an Internet Gateway only if one doesn't already exist
resource "aws_internet_gateway" "gw" {
  vpc_id = data.aws_vpc.main.id
  count  = data.aws_internet_gateway.existing_igw.id == "" ? 1 : 0

  tags = {
    Name = "MainInternetGateway"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # CIDR block for the public subnet
  availability_zone       = "eu-north-1a"  # Specify availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"  # CIDR block for the private subnet
  availability_zone       = "eu-north-1a"  # Specify availability zone
  tags = {
    Name = "PrivateSubnet"
  }
}

# Create a NAT Gateway in the Public Subnet, using the existing Elastic IP
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "eipalloc-0f31490b059b9694f"  # Use your existing Elastic IP's allocation ID
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.gw]  # Ensure the IGW is created before the NAT Gateway
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[0].id
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
  vpc_id = data.aws_vpc.main.id

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
