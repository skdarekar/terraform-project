provider "aws" {
  region = "ap-south-1"
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}

# 1. Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "production"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-gw"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-route-table"
  }
}

# Terraform Variables

variable "subnet_prefix" {
  description = "cidr block for subnet"
  # type = string
  # default = "10.0.1.0/24"
}

# 4. Create a Subnet

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "ap-south-1a"
  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "ap-south-1a"
  tags = {
    Name = var.subnet_prefix[1].name
  }
}

# 5. Associate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create security group to allow ports 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create an network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "nw-interface" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7

# resource "aws_eip" "one" {
#   vpc                       = true
#   network_interface         = aws_network_interface.nw-interface.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on = [
#     aws_internet_gateway.gw
#   ]
# }

# 9. Create an Ubantu server and install/enable apache2

resource "aws_instance" "my-web-instace" {
  ami = "ami-0f8ca728008ff5af4"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "personal_aws_key_pair"

  # network_interface {
  #   device_index = 0
  #   network_interface_id = aws_network_interface.nw-interface.id
  # }

  user_data = <<EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2 
              sudo bach -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    "Name" = "web server"
  }
}

# Outputs
output "server_id" {
  value = aws_instance.my-web-instace.id
}

output "server_public_ip" {
  value = aws_instance.my-web-instace.public_ip
}

