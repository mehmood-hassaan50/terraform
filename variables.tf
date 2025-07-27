variable "vpc" {
  description = "VPC Name"
  type        = string
}

variable "subnet" {
  description = "Name of the Subnet"
  type        = string
}

variable "sec_ec2" {
  description = "EC2 Security Group Name"
  type        = string
}

variable "s3bucket" {
  description = "Name of the S3 Bucket"
  type        = string
}

variable "s3bucketacl" {
  description = "Name of the Subnet ACL"
  type        = string
}

variable "sec_rds" {
  description = "Name of the Subnet for RDS"
  type        = string
}

variable "launch_template" {
  description = "Name of the AMI Laucnh Template"
  type        = string
}

variable "postgresrds" {
  description = "Name of the Postgres RDS Instance"
  type        = string
}