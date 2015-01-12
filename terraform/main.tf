### General

provider "aws" {
  region = "us-west-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
}

### Subnets

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "consul_cluster" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"
}

### Security groups

resource "aws_security_group" "public" {
  vpc_id = "${aws_vpc.default.id}"
  name = "public"
  description = "SSH and HTTP from everywhere"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul" {
  name = "consul"
  description = "Consul internal traffic + maintenance."
  vpc_id = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    self = true
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    self = true
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    self = true
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    self = true
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    self = true
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    self = true
    cidr_blocks = ["10.0.0.0/16"]
  }
}

### Routers

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "dmz" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

### Instances

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public.id}"

  ami = "${var.grafana-ami}"
  security_groups = ["${aws_security_group.public.id}", "${aws_security_group.consul.id}"]
  associate_public_ip_address = true
}

resource "aws_instance" "consul0" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "10.0.1.100"

  ami = "${var.consul-ami}"
  security_groups = ["${aws_security_group.consul.id}"]
}
resource "aws_instance" "consul1" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "10.0.1.101"

  ami = "${var.consul-ami}"
  security_groups = ["${aws_security_group.consul.id}"]
}
resource "aws_instance" "consul2" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "10.0.1.102"

  ami = "${var.consul-ami}"
  security_groups = ["${aws_security_group.consul.id}"]
}