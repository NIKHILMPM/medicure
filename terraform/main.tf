provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "medicure_ec2" {
  ami                         = "ami-0f9de6e2d2f067fca"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "jjk"

  tags = {
    Name = "Medicure-Server"
  }

  vpc_security_group_ids = [aws_security_group.medicure_sg.id]
}

resource "aws_security_group" "medicure_sg" {
  name        = "medicure_sg"
  description = "Allow SSH and Kubernetes app access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30081
    to_port     = 30081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
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

output "ec2_public_ip" {
  value = aws_instance.medicure_ec2.public_ip
}
