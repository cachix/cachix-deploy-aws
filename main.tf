terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "cachix_deploy_ami" {
  source  = "git::https://github.com/cachix/cachix-deploy-amis"
  release = "stable"
}

resource "aws_secretsmanager_secret" "cachix-agent-token" {
  name = "cachix-agent-token"
}

resource "aws_secretsmanager_secret_version" "cachix-agent-token" {
  secret_id     = aws_secretsmanager_secret.cachix-agent-token.id
  secret_string = var.cachix-agent-token
}

resource "tls_private_key" "ssh-key" {
  algorithm   =  "ED25519"
}

resource "local_file" "private_key" {
  content         =  tls_private_key.ssh-key.private_key_openssh
  filename        =  "openssh.pem"
  file_permission =  0400
}

resource "aws_key_pair" "root-key" {
  key_name   = "root-key"
  public_key = tls_private_key.ssh-key.public_key_openssh
}

resource "aws_security_group" "ssh" {
  name = "ssh"

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "instance1" {
  ami = cachix_deploy_ami.id
  instance_type = "t3.nano"
  key_name = aws_key_pair.root-key.key_name
  security_groups = [aws_security_group.ssh.name]

  connection {
    type     = "ssh"
    user     = "root"
    private_key = tls_private_key.ssh-key.private_key_openssh
    host     = self.public_ip
  }

  provisioner "local-file" {
    source = "cachix-agent.secret"
    target = "/etc/cachix-agent.token"
  }

  lifecycle {
    create_before_destroy = true
  }
}
