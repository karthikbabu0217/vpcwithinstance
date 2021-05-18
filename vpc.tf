provider "aws" {
  region     = "us-east-2"
  access_key = "AKIAYJ4UAQW5BXIYFLCR"
  secret_key = "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"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "my-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.3.0/24"

  tags = {
    Name = "my-priavte"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "MY-IGW"
  }
}

resource "aws_eip" "ip" {
  vpc      = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.private.id

  tags = {
    Name = "NAT-Gateway"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "custom"
  }
}

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "main"
  }
}


resource "aws_route_table_association" "association_1" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "association_2" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "SG" {
  name        = "first-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "first-sg"
  }
}

resource "aws_instance" "VM-in-new-vpc" {
  ami                          = "ami-00399ec92321828f5"
  instance_type                = "t2.micro"
  subnet_id                    = aws_subnet.public.id
  associate_public_ip_address  = true
  vpc_security_group_ids       = [aws_security_group.SG.id]


   tags = {

    name = "my-vpc-instance"
  }


}

