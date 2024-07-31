
resource "aws_security_group" "tracert" {
  name   = "ICMP and SSH"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP echo requests"
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tracert"
  }
}

resource "aws_security_group" "tracert-geneve" {
  name   = "GWLB Instance"
  vpc_id = aws_vpc.glbet.id



  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["10.10.0.0/16"]
  }  

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      self = true
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tracert"
  }
}

resource "aws_instance" "app-ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id                   = aws_subnet.app_subnet.id
  vpc_security_group_ids      = [aws_security_group.tracert.id]
  associate_public_ip_address = false
  # User data script to update the command prompt
  user_data = <<-EOF
              #!/bin/bash
              echo 'export PS1="\\u@app-ec2\\w\\\$ "' >> /home/ec2-user/.bashrc
              EOF
  tags = {
    Name = "app-ec2"
  }
}

resource "aws_instance" "db-ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id                   = aws_subnet.db_subnet.id
  vpc_security_group_ids      = [aws_security_group.tracert.id]
  associate_public_ip_address = false
  # User data script to update the command prompt
  user_data = <<-EOF
              #!/bin/bash
              echo 'export PS1="\\u@db-ec2\\w\\\$ "' >> /home/ec2-user/.bashrc
              EOF
  tags = {
    Name = "db-ec2"
  }
}



resource "aws_instance" "fw-ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id                   = aws_subnet.glbet_subnet.id
  vpc_security_group_ids      = [aws_security_group.tracert-geneve.id]
  associate_public_ip_address = false
  user_data = <<-EOF
    #!/bin/bash -ex
    echo 'export PS1="\\u@fw-ec2\\w\\\$ "' >> /home/ec2-user/.bashrc
    yum -y groupinstall "Development Tools"
    yum -y install cmake3
    yum -y install tc || true
    yum -y install iproute-tc || true
    cd /root
    git clone https://github.com/aws-samples/aws-gateway-load-balancer-tunnel-handler.git
    cd aws-gateway-load-balancer-tunnel-handler
    cmake3 .
    make
    sudo setcap cap_net_admin=eip ./gwlbtun
    echo "[Unit]" > /usr/lib/systemd/system/gwlbtun.service
    echo "Description=AWS GWLB Tunnel Handler" >> /usr/lib/systemd/system/gwlbtun.service
    echo "" >> /usr/lib/systemd/system/gwlbtun.service
    echo "[Service]" >> /usr/lib/systemd/system/gwlbtun.service
    echo "ExecStart=/root/aws-gateway-load-balancer-tunnel-handler/gwlbtun -c /root/aws-gateway-load-balancer-tunnel-handler/example-scripts/create-passthrough.sh -p 80" >> /usr/lib/systemd/system/gwlbtun.service
    echo "Restart=always" >> /usr/lib/systemd/system/gwlbtun.service
    echo "RestartSec=5s" >> /usr/lib/systemd/system/gwlbtun.service
    systemctl daemon-reload
    systemctl enable --now --no-block gwlbtun.service
    systemctl start gwlbtun.service
  EOF
  tags = {
    Name = "fw-ec2"
  }
}


resource "aws_ec2_instance_connect_endpoint" "fw-endpoint" {
  subnet_id = aws_subnet.glbet_subnet.id
  security_group_ids = [aws_security_group.tracert-geneve.id]
  depends_on = [aws_subnet.glbet_subnet,aws_security_group.tracert-geneve]
  tags = {
    Name = "fw-ec2-endpoint"
  }
}


resource "aws_ec2_instance_connect_endpoint" "app-endpoint" {
  subnet_id = aws_subnet.app_subnet.id
  security_group_ids = [aws_security_group.tracert.id]
  depends_on = [aws_subnet.app_subnet]
  tags = {
    Name = "app-ec2-endpoint"
  }
}

