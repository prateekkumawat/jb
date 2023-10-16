variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "regions" {}
variable "vpc_cidr" {}
variable "public_subnet_vpc_cidr" {
    type = list
}
variable "private_subnet_vpc_cidr" {
    type = list
}
variable "db_password" {}