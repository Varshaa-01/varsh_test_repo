provider "aws" {
  region = var.myregion
  access_key = var.myaccesskey
  secret_key = var.mysecretkey
}

resource "aws_vpc" "myvpc" {
  instance_tenancy = "default"
  cidr_block = var.mycidr
  tags = {
    Name = "varsh-VPC"
   }
}

resource "aws_subnet" "mysubnet" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = var.mycidrsub
  tags = {
    Name = "varsh-VPC-Subnet1"
   }
}
/*
resource "aws_subnet" "mysubnet2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = var.mycidrsub2
  availability_zone = "ap-south-1c"
  tags = {
    Name = "varsh-VPC-Subnet2"
   }
}
*/
resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "varsh-VPC-IGateway"
  }
}

resource "aws_route_table" "myroute1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}

resource "aws_route_table_association" "myroute1_association" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.myroute1.id
}

resource "aws_security_group" "mysg" {
  name        = "allow_ssh_http"
  description = "Allow ssh and http traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_instance" "myvm1" {
  ami = "ami-0a0f1259dd1c90938"
  instance_type = "t2.micro"
  key_name = "testkey1"
  subnet_id = aws_subnet.mysubnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.mysg.id]
  root_block_device {
    volume_type = "gp2"
  }
  tags = {
    Name = "Server1"
  }
}

resource "aws_ebs_volume" "myebs" {
  availability_zone = "ap-south-1a"
  size              = 5
  type = "gp2"

  tags = {
    Name = "MyEBS"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.myebs.id
  instance_id = aws_instance.myvm1.id
}

resource "aws_instance" "myvm2" {
  ami = "ami-03f4878755434977f"
  instance_type = "t2.micro"
  key_name = "testkey1"
  subnet_id = aws_subnet.mysubnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.mysg.id]
  root_block_device {
    volume_type = "gp2"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update
  sudo apt install apache2 -y
  echo "Hello World" > /var/www/html/index.html
  sudo systemctl restart apache2
  sudo systemctl enable apache2
  EOF

  tags = {
    Name = "WebServer1"
  }
}

resource "null_resource" "test1" {
 triggers = {
  always_run = "${timestamp()}"
 }

connection {
  type = "ssh"
  user = "ubuntu"
  host = aws_instance.myvm2.public_ip
  private_key = file("~/testkey1.pem")
  }

provisioner "remote-exec" {
  inline = [
  "sudo systemctl start apache2"
  ]
}
}


