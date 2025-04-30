provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "medicure_ec2" {
  ami                         = "ami-053b0d53c279acc90" # ✅ Ubuntu 22.04 LTS (official, stable)
  instance_type               = "t2.micro"
  key_name                    = "jjk"
  associate_public_ip_address = true

  tags = {
    Name = "Medicure-Server"
  }

  vpc_security_group_ids = [aws_security_group.medicure_sg.id]
}

resource "aws_security_group" "medicure_sg" {
  name        = "medicure_sg"
  description = "Allow SSH, Kubernetes NodePort, and API access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort range for Kubernetes services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional: Allow Kubernetes API access (only if needed)
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
