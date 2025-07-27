# VPC
resource "aws_vpc" var.vpc {
  cidr_block = "10.0.0.0/16"
}

# Subnet in us-east-2b
resource "aws_subnet" var.subnet {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
}

resource "aws_s3_bucket" var.s3bucket {
  bucket = "mys3bucketHassaan"
}

resource "aws_s3_bucket_acl" var.s3bucketacl {
  bucket = aws_s3_bucket.mybucket.id
  acl    = "private"
}

# Security Group for EC2
resource "aws_security_group" var.sec_ec2 {
  name        = "ec2_sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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

# Security Group for RDS
resource "aws_security_group" var.sec_rds {
  name        = "rds_sg"
  description = "Allow Postgres"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get Latest Amazon Linux 2 AMI for us-east-2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template
resource "aws_launch_template" var.launch_template {
  name_prefix   = "web-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = "your-key-name" # Replace with your key pair

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.shared_sg.id]
  }
}

# RDS Instance (Postgres)
resource "aws_db_instance" var.postgresrds {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = random_password.db_password.result
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.shared_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

 

resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "db-password-secret"
  recovery_window_in_days = 7
}

 

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({ username = "admin", password = random_password.db_password.result })
}