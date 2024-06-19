terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.19.0"
    }
  }
}
# provider "aws" {
#     access_key = "ASIA5FTY622APRLMU3NR"
#     secret_key = "MxrDUWiox7+8LonwH5ckgmSj+w2qlLNgoSvbZFQz"
#     region = "us-east-1"
#     token = "FwoGZXIvYXdzEK3//////////wEaDJ9yyoi2Itqed1ut4SLPAZ0+1pVSbSwVi693i9SV6InMdSLU/qp+vtcUpG8E9FGIQgw1gYJRy3TWGEYh2/H6GW2xLMx90jkoe5KmlmJ82blkXF/zgKRwyUaEzstfia+GLrLWZjz9eDGnZwGoOOL3gPE2i5MdcDOQIag/ogx1a2AuURX4OvCv2Q1WZYzVr5WI4DwTHJTJDhZwSWx/tT08AtBiMK/04Nl3Hj3D2qoHDat6GAtHfCVbRwllaR4tYDEf7CJat/gQMQugti2IIQWaDDvsWKh4RtIe2LdB2IvDfijE9J2vBjItQUPcX3K6JEk6eKeE/OW4Sd4qXz2QlzEbZXWNLF9AbZelveGmbDPbsZG2Hrtv"
# }

module "vpc" {
    #source = "terraform-aws-modules/vpc/aws"
    #version = "5.5.2"
    source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=26c38a66f12e7c6c93b6a2ba127ad68981a48671"  # commit hash of version 5.0.0
    
    name = "Lab VPC"
    cidr = "10.200.0.0/16"

    azs = ["us-east-1a", "us-east-1b"]
    private_subnets = ["10.200.101.0/24","10.200.102.0/24"]
    public_subnets = ["10.200.1.0/24","10.200.2.0/24"]

    enable_nat_gateway = true
    one_nat_gateway_per_az = true
    single_nat_gateway = false

    tags = {
        Terraform = "true"
        Environment = "dev"}
}

resource "aws_security_group" "MySG" {
  name = "MySG"
  description = "My Rules"
  vpc_id = module.vpc.vpc_id

  ingress = {
    name = "HTTP"
    description = "Ingress HTTP from anywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    name = "ICMP"
    description = "Ingress ICMP from anywhere"
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]

    name = "SSH"
    description = "Ingress SSH from anywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  } 

  resource "aws_instance" "srv1" {
    ami           = "ami-0440d3b780d96b29d"
    instance_type = "t2.micro"
    key_name = "vockey"
    subnet_id = module.vpc.public_subnets[0] 
    vpc_security_group_ids = [aws_security_group.MySG.id]
    user_data = <<-EOF
                #!/bin/bash
                # Install Apache Web Server and PHP 
                dnf install -y httpd wget php mariadb105-server 
                # Download Lab files 
                wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-100-ACCLFO-2/2
                lab2-vpc/s3/lab-app.zip 
                unzip lab-app.zip -d /var/www/html/ 
                # Turn on web server 
                chkconfig httpd on 
                service httpd start
                EOF
  }

  resource "aws_instance" "srv2" {
    ami           = "ami-0440d3b780d96b29d"
    instance_type = "t2.micro"
    key_name = "vockey"
    subnet_id = module.vpc.public_subnets[1]
    vpc_security_group_ids = [aws_security_group.MySG.id]
    user_data = <<-EOF
                #!/bin/bash
                # Install Apache Web Server and PHP 
                dnf install -y httpd wget php mariadb105-server 
                # Download Lab files 
                wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-100-ACCLFO-2/2
                lab2-vpc/s3/lab-app.zip 
                unzip lab-app.zip -d /var/www/html/ 
                # Turn on web server 
                chkconfig httpd on 
                service httpd start
                EOF
  }

  resource "aws_lb_target_group" "MyTargets" {
    name = "MyTargets"
    port = 80
    protocol = "HTTP"
    vpc_id = module.vpc.vpc_id
  }

  resource "aws_lb" "MyLB" {
    name = "MyLB"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.MySG.id]
    subnets = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]] 
  }