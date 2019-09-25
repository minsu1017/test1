resource "aws_vpc" "awsvpc" {
  cidr_block           = "128.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name = "user28-vpc"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id            = "${aws_vpc.awsvpc.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block        = "128.0.1.0/24"
  tags = {
    Name = "user28-public-1a"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id            = "${aws_vpc.awsvpc.id}"
  availability_zone = "ap-northeast-1c"
  cidr_block        = "128.0.2.0/24"
  tags = {
    Name = "user28-public-1b"
  }
}

resource "aws_internet_gateway" "awsipg" {
  vpc_id = "${aws_vpc.awsvpc.id}"
  tags = {
    Name = "user28-igw"
  }
}

resource "aws_eip" "nat-user28-1a" {
  vpc = true
  tags = {
    Name = "user28-eip1"
  }
}

resource "aws_eip" "nat-user28-1c" {
  vpc = true
  tags = {
    Name = "user28-eip2"
  }
}

resource "aws_route_table" "awsrtp" {
  vpc_id = "${aws_vpc.awsvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.awsipg.id}"
  }
}

resource "aws_route_table_association" "awsrtp1a" {
  subnet_id      = "${aws_subnet.public_1a.id}"
  route_table_id = "${aws_route_table.awsrtp.id}"
}

resource "aws_route_table_association" "awsrtp1b" {
  subnet_id      = "${aws_subnet.public_1b.id}"
  route_table_id = "${aws_route_table.awsrtp.id}"
}

resource "aws_default_security_group" "awssecurity" {
  vpc_id = "${aws_vpc.awsvpc.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "user28-sg"
  }
} 

resource "aws_default_network_acl" "awsnetworkacl" {
  default_network_acl_id = "${aws_vpc.awsvpc.default_network_acl_id}"

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  subnet_ids = [
    "${aws_subnet.public_1a.id}",
    "${aws_subnet.public_1b.id}",
  ]
}

variable "amazon_linux" {
  default = "ami-0ab3e16f9c414dee7"
}



resource "aws_security_group" "webserverSecurutyGroup" {
  name        = "user28-webserverSecurutyGroup"
  description = "open ssh port for webserverSecurutyGroup"

  vpc_id = "${aws_vpc.awsvpc.id}"

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

resource "aws_instance" "user28-web1" {
  ami               = "${var.amazon_linux}"
  availability_zone = "ap-northeast-1a"
  instance_type     = "t2.micro"
  key_name = "user28-key"
  vpc_security_group_ids = [
    "${aws_security_group.webserverSecurutyGroup.id}",
    "${aws_default_security_group.awssecurity.id}",
  ]

  subnet_id                   = "${aws_subnet.public_1a.id}"
  associate_public_ip_address = true
  tags = {
    Name = "user28-web1"
  }
}