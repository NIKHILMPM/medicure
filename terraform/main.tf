provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "medicure_ec2" {
  ami                         = "ami-0f9de6e2d2f067fca"
  instance_type               = "t2.medium"
  key_name                    = "jjk"
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.medicure_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -xe

              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

              apt install -y containerd
              mkdir -p /etc/containerd
              containerd config default > /etc/containerd/config.toml
              systemctl restart containerd

              mkdir -p /etc/apt/keyrings
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
                gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
              chmod 0644 /etc/apt/keyrings/kubernetes.gpg

              echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
                > /etc/apt/sources.list.d/kubernetes.list

              apt-get update -y
              apt-get install -y kubelet kubeadm kubectl
              apt-mark hold kubelet kubeadm kubectl

              swapoff -a
              sed -i '/ swap / s/^/#/' /etc/fstab
              EOF

  tags = {
    Name = "Medicure-K8s-Node"
  }
}

resource "aws_security_group" "medicure_sg" {
  name        = "medicure_sg"
  description = "Allow SSH and NodePort access"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
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
