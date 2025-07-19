# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnet in us-east-2b
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "rtable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate Route Table
resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rtable.id
}

# Shared Security Group for EC2 and RDS
resource "aws_security_group" "shared_sg" {
  name        = "shared-sg"
  description = "Allow SSH and MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
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
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = "your-key-name" # Replace with your key pair

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.shared_sg.id]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2
  min_size             = 2
  max_size             = 3
  vpc_zone_identifier  = [aws_subnet.main.id]

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  force_delete              = true
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.main.id]
}

# RDS Instance (MySQL)
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Password1234"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.shared_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
}
