# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "ami-0a2e7efb4257c0907" # Amazon Linux 2023 pour ca-central-1
  instance_type          = "t3a.nano" # Taille minimale pour un bastion
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  # Script de démarrage pour configurer le bastion comme proxy SSH
  user_data = <<-EOF
    #!/bin/bash
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
    systemctl restart sshd
    yum update -y
    yum install -y mysql
  EOF

  tags = merge(local.tags, {
    Name = "${var.project}-bastion-${var.environment}"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Elastic IP pour le bastion (pour avoir une IP fixe)
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  
  tags = merge(local.tags, {
    Name = "${var.project}-bastion-eip-${var.environment}"
  })

  lifecycle {
    prevent_destroy = true
  }
}