resource "aws_vpc" "testing_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Testing VPC"
  }
}

resource "aws_subnet" "testing_public_subnet_1a" {
  vpc_id            = aws_vpc.testing_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Testing Public Subnet 1a"
  }
}

resource "aws_subnet" "testing_private_subnet_1a" {
  vpc_id            = aws_vpc.testing_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Testing Private Subnet 1a"
  }
}

resource "aws_subnet" "testing_public_subnet_1b" {
  vpc_id            = aws_vpc.testing_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Testing Public Subnet 1b"
  }
}

resource "aws_subnet" "testing_private_subnet_1b" {
  vpc_id            = aws_vpc.testing_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Testing Private Subnet 1b"
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
  subnet_id      = aws_subnet.testing_public_subnet_1a.id
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

resource "aws_lb_target_group" "front" {
  name     = "application-front"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.testing_vpc.id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "attach-testing" {
  target_group_arn = aws_lb_target_group.front.arn
  target_id        = aws_instance.testing_ec2.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "attach-deployment" {
  target_group_arn = aws_lb_target_group.front.arn
  target_id        = aws_instance.deployment_ec2.id
  port             = 5000
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front.arn
  port              = "5000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front.arn
  }
}

resource "aws_lb" "front" {
  name               = "front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.testing_public_subnet_1a.id, aws_subnet.testing_public_subnet_1b.id]

  enable_deletion_protection = false

  tags = {
    Environment = "front"
  }
}

resource "aws_instance" "testing_ec2" {
    ami = var.ami-ubunto-2204
    instance_type = var.ins_type 
    subnet_id                   = aws_subnet.testing_public_subnet_1a.id
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

resource "aws_instance" "deployment_ec2" {
    ami = var.ami-ubunto-2204
    instance_type = var.ins_type 
    subnet_id                   = aws_subnet.testing_public_subnet_1b.id
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
sudo docker pull lilachamar/flask-sql-i:latest
sudo docker run -d -p 5000:5000 lilachamar/flask-sql-i:latest
EOF
    tags = {
        Name = "deployment_ec2"
    }    
}

