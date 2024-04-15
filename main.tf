####Declaring providers############

provider "aws"{
  access_key = "#dummy_code"
  secret_key = "#dummy_creds"
  region   = "us-east-1"
}

#####Defining a new vpc#################

resource "aws_vpc" "prod-vpc"{
  cidr_block = "10.0.0.0/16"
}

#############Declaring a subnet inside vpc################

resource "aws_subnet" "prod-vpc-subnet1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "project-A"
  }
}

#####Internet Gateway#############

resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-ig"
  }
}

########## NIC ###############

resource "aws_network_interface" "backend1-nic" {
  subnet_id       = aws_subnet.prod-vpc-subnet1.id
  private_ips     = ["10.0.1.50"]

  attachment {
    instance     = aws_instance.backend-instance1
    device_index = 1
  }
}

resource "aws_network_interface" "backend2-nic" {
  subnet_id       = aws_subnet.prod-vpc-subnet1.id
  private_ips     = ["10.0.1.51"]

  attachment {
    instance     = aws_instance.backend-instance2
    device_index = 1
  }
}
################### Backend Instances ################

resource "aws_instance" "backend-instance1" {
  ami           = "#dummy_ami" # us-east1
  instance_type = "t2.micro"


}


resource "aws_instance" "backend-instance2" {
  ami           = "#dummy_ami" # us-east1
  instance_type = "t2.micro"


}


######## Security Group for firewall for Application Load balancer ##############



resource "aws_security_group" "allow_443" {
  name        = "allow_443"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod_sg_lb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_443.id
  cidr_ipv4         = aws_vpc.prod-vpc.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

################# Application Load balancer #######################

resource "aws_lb" "app1" {
  name               = "app1"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_443.id]
  subnets            = [aws_subnet.prod-vpc-subnet1.id]

  enable_deletion_protection = true

  tags = {
    Environment = "alb-app1-production"
  }
}

#######target-group############

resource "aws_lb_target_group" "backend1-group" {
  name     = "backend1-group"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.prod-vpc.id
  tags = {
    Environment = "alb-app1-production"
  }  
}

resource "aws_lb_target_group" "backend2-group" {
  name     = "backend2-group"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.prod-vpc.id
  tags = {
    Environment = "alb-app1-production"
  }  
}