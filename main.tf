resource "aws_vpc" "testing_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Testing VPC"
  }
}

resource "aws_subnet" "testing_public_subnet" {
  vpc_id            = aws_vpc.testing_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Testing Public Subnet"
  }
}

resource "aws_subnet" "testing_private_subnet" {
  vpc_id            = aws_vpc.testing_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Testing Private Subnet"
  }
}

resource "aws_internet_gateway" "testing_ig" {
  vpc_id = aws_vpc.testing_vpc.id

  tags = {
    Name = "Testing Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.testing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testing_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.testing_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.testing_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.testing_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "testing_ec2" {
    ami = var.ami-ubunto-2204
    instance_type = var.ins_type 
    subnet_id                   = aws_subnet.testing_public_subnet.id
    vpc_security_group_ids      = [aws_security_group.web_sg.id]
    associate_public_ip_address = true
    key_name = var.key_name
    user_data = <<-EOF
#!/bin/bash
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
echo "Pulling and running Docker container..."
sudo docker pull lilachamar/flask-sql-i:testing
sudo docker run -d -p 5000:5000 lilachamar/flask-sql-i:testing
EOF
    tags = {
        Name = "testing_ec2"
    }    
}

