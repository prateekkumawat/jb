terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.13.1"
    }
  }
}

provider "aws" {
 access_key = var.aws_access_key
 secret_key = var.aws_secret_key
 region = var.regions
}

# Define key gor aws key pem 
resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096 
}

# aws key pair define 
resource "aws_key_pair" "demo_key_pair" {
  key_name   = "mykey.pem"
  public_key = tls_private_key.demo_key.public_key_openssh
}

resource "local_file" "mykey" {
   filename = "mykey.pem"
   content = tls_private_key.demo_key.private_key_pem
}

# Create Vpc Resource with public Private Subnet 

resource "aws_vpc" "vpc1" { 
    cidr_block = var.vpc_cidr
    instance_tenancy = "default"

    tags = {
      Name = "Project_Terra_DB_VPC"
    }
}

#Create a Public Subnet 1 in az1 
resource "aws_subnet" "Public1" { 
    cidr_block = var.public_subnet_vpc_cidr[0]
    vpc_id = aws_vpc.vpc1.id
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = "true"
    
    tags = {
      Name = "Project_Terra_DB_Public_Subnet1_az1a"
    }
}

# Create a Public Subnet 2 in az2
resource "aws_subnet" "Public2" { 
    cidr_block = var.public_subnet_vpc_cidr[1]
    vpc_id = aws_vpc.vpc1.id
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = "true"
    
    tags = {
      Name = "Project_Terra_DB_Public_Subnet2_az1b"
    }
}

# Create a Private Subnet 1 in az1
resource "aws_subnet" "Private1" { 
    cidr_block = var.private_subnet_vpc_cidr[0]
    vpc_id = aws_vpc.vpc1.id
    availability_zone = "ap-south-1a"
    
    tags = {
      Name = "Project_Terra_DB_Private_Subnet1_az1a"
    }
}

# Create a Private Subnet 1 in az2
resource "aws_subnet" "Private2" { 
    cidr_block = var.private_subnet_vpc_cidr[1]
    vpc_id = aws_vpc.vpc1.id
    availability_zone = "ap-south-1b"
    
    tags = {
      Name = "Project_Terra_DB_Private_Subnet2_az1b"
    }
}


# Create a Igw and attach with vpc
resource "aws_internet_gateway" "vpc1igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
      Name = "Project_Terra_DB_igw"
    }
}

# Create a Public RT for vpc 
resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.vpc1.id

  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1igw.id
  }

   tags = {
      Name = "Project_Terra_DB_PublicRT"
    }
}

# Create a Private RT for VPC 
resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.vpc1.id

   tags = {
      Name = "Project_Terra_DB_PrivateRT"
    }
}

# Assosiate Public subnet1 with PublicRT  
resource "aws_route_table_association" "assosiatepublicsubnet1" {
  subnet_id      = aws_subnet.Public1.id
  route_table_id = aws_route_table.PublicRT.id
}

# Assosiate Public subnet2 with PublicRT  
resource "aws_route_table_association" "assosiatepublicsubnet2" {
  subnet_id      = aws_subnet.Public2.id
  route_table_id = aws_route_table.PublicRT.id
}

# Assosiate Private subnet1 with PrivateRT  
resource "aws_route_table_association" "assosiateprivatesubnet1" {
  subnet_id      = aws_subnet.Private1.id
  route_table_id = aws_route_table.PrivateRT.id
}

# Assosiate Private subnet1 with PrivateRT  
resource "aws_route_table_association" "assosiateprivatesubnet2" {
  subnet_id      = aws_subnet.Private2.id
  route_table_id = aws_route_table.PrivateRT.id
}

# crate subnet group for DB 
resource "aws_db_subnet_group" "dbsubgrp" {
  name       = "main"
  subnet_ids = [aws_subnet.Private1.id, aws_subnet.Private2.id] 

  tags = {
    Name = "Project_Terra_DB_Subnet_Group"
  }
}

resource "aws_db_parameter_group" "dbpera" {
  name   = "rds-pg"
  family = "mysql8.0"
}

# Create DB Instance using RDS service
resource "aws_db_instance" "rdsprivate" {
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.dbsubgrp.name
  parameter_group_name = aws_db_parameter_group.dbpera.name
  skip_final_snapshot  = true
}