
#----------------------------------------------------------
provider "aws" {
  region     = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "pavlov-terraform-state"                     // Bucket where to SAVE Terraform State
    key    = "servers/terraform.tfstate"                  // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                                  // Region where bucket created
  }
}
#====================================================================


data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "pavlov-terraform-state"                     // Bucket where to SAVE Terraform State
    key    = "test1/terraform.tfstate"                    // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                                  // Region where bucket created
  }
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
#===============================================================


resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id]
  subnet_id              = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  key_name               = "ec2"

  tags = {
    Name = "${var.env}-WebServer"
  }
}

resource "aws_security_group" "webserver" {
  name = "WebServer Security Group"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-web-server-sg"
    Owner = "pavlov"
  }
}

#=================================================================
