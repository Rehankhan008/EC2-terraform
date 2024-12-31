# Define provider
provider "aws" {
  region = "ap-south-1" # Replace with your desired AWS region
}
# Security Group for EC2
resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH traffic"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create two EC2 instances in different AZs
resource "aws_instance" "web_servers" {
  count         = 2
  ami           = "ami-053b12d3152c0cc71" # Replace with the latest Amazon Linux 2 AMI for your region
  instance_type = "t2.micro"
  key_name      = "mum-key" # Use your existing key pair

  # Assign subnets based on count
  subnet_id = [
    "subnet-04a6a3611a6dff5d8", # Subnet in ap-south-1a
    "subnet-008d71cd025e5b544"  # Subnet in ap-south-1b
  ][count.index]

  security_groups = [aws_security_group.allow_http_ssh.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              apt-cache policy docker-ce
              sudo apt install -y docker-ce
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
            EOF

  tags = {
    Name = "WebServer-${count.index + 1}"
  }
}

# Output the Public IPs of both instances
output "instance_ips" {
  value = aws_instance.web_servers[*].public_ip
}
