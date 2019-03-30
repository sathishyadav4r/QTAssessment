provider "aws" {
  access_key = "AKIAWKWP5LQUX2A5R3IS"
  secret_key = "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"
  region     = "us-east-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

tags = {
    Name = "firstvpc"
}
}
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "myfirstinternetgetway"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "subnet2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "subnet3"
  }
}

resource "aws_route_table" "publicroute" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }


  tags = {
    Name = "publicroute"
  }
}

resource "aws_route_table_association" "subnetassociation" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.publicroute.id}"
}

resource "aws_route_table_association" "subnetassociation1" {
  subnet_id      = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.publicroute.id}"
}

resource "aws_route_table_association" "subnetassociation2" {
  subnet_id      = "${aws_subnet.subnet3.id}"
  route_table_id = "${aws_route_table.publicroute.id}"
}

resource "aws_security_group" "allow_alls" {
  name        = "allow_alls"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_vpc.main.id}"

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

resource "aws_instance" "webserver" {
  ami = "ami-0653e888ec96eab9b"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet1.id}"
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.allow_alls.id}"]
  key_name = "jenkin.pem"

  tags = {
    Name = "webserver"
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("./jenkin.pem")}"
  }

provisioner "file" {
  source = "/home/jenkins/playbooks/QTAss.yml"
  destination = "/home/ubuntu/QTAss.yml"
  }

provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo sudo apt install software-properties-common -y",
      "sudo apt-add-repository ppa:ansible/ansible -y",
      "sudo apt-get update",
      "sudo apt install python3-minimal -y",
      "sudo apt install ansible -y",
      "sudo ansible-playbook -u ubuntu --private-key ./jenkin.pem -i '${aws_instance.webserver.public_ip},' QTAss.yml" 
    
    ]
  }
}

 
