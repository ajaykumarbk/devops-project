provider "aws" {
  region="us-east-1"
}

resource "aws_instance" "demo_instance" {
  ami           = "ami-020cba7c55df1f615" 
  instance_type = "t2.micro"
  key_name = "demo"
  security_groups = "demo-sg"

  tags = {
    Name = "DemoInstance"
  }
  
}

resource "aws_security_group" "demo-sg" {
  name = "demo-sg"
  description = "Security group for demo instance"

 ingress = {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0.0/0"]

    egress = {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0   
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
 }
  
}

}

