resource "aws_vpc" "demo" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
        Name = "DemoVPC"
    }
  
}

resource "aws_subnet" "demo_public_subnet-01" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
    
    tags = {
        Name = "DemoPublicSubnet-01"
    }
  
}

resource "aws_subnet" "demo_public_subnet-02" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
    
    tags = {
        Name = "DemoPublicSubnet-02"
    }
  
}

resource "aws_internet_gateway" "demo-ig" {
    vpc_id = aws_vpc.demo.id
    
    tags = {
        Name = "DemoInternetGateway"
    }
  
}

resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo.id
  
  route {
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.demo-ig.id
  }
}

resource "aws_route_table_association" "public-sunbnet-association-01" {
  subnet_id = aws_subnet.demo_public_subnet-01.id
  route_table_id = aws_route_table.demo_public_rt.id
}

resource "aws_route_table_association" "public-sunbnet-association-02" {
  subnet_id = aws_subnet.demo_public_subnet-02.id
  route_table_id = aws_route_table.demo_public_rt.id
}

resource "aws_security_group" "demo-sg" {
  vpc_id = aws_vpc.demo.id
  name        = "demo-sg"
  description = "Allow SSH"

  tags = {
    Name = "allow_SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id=aws_security_group.demo-sg.id
  from_port        = 22
  cidr_ipv4        = "0.0.0.0/0"
  ip_protocol      = "tcp"
  to_port          = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

variable "aws_instance"{
  default = ["masetr", "worker","ansible"]
}

resource "aws_instance" "demo_ec2" {
  for_each = toset(var.aws_instance)
  ami = "ami-020cba7c55df1f615" # Example AMI, replace with your desired AMI ID
  instance_type = "t2.micro"
  key_name = "data" # Replace with your key pair name
  subnet_id = aws_subnet.demo_public_subnet-01.id # Assign to the first public subnet
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  associate_public_ip_address = true

    tags = {
        Name = each.key
    }

    user_data = each.key == "ansible" ? file("${path.module}/install-ansible.sh") : null
}

resource "null_resource" "copy_file_ansible" {
  depends_on = [ aws_instance.demo_ec2["ansible"] ]

  connection {
    type = "ssh"
    host= aws_instance.demo_ec2["ansible"].public_ip
    user = "ubuntu"
    private_key = file("/home/cloud_user/keypair/data.pem")
  }

  provisioner "file" {
    source = "/home/cloud_user/complete-devops/ansible"
    destination = "/home/ubuntu/ansible"
    
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'File copied to Ansible server'",
      "ls -l /home/ubuntu"
    ]
  }
}
