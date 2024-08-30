# main.tf

provider "aws" {
  region = "us-east-1"
}

# Create a new VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "rds_vpc"
  }
}

# Create subnets in different availability zones within the new VPC
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet_b"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "rds_ig" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_ig"
  }
}

# Create a Route Table
resource "aws_route_table" "rds_route_table" {
  vpc_id = aws_vpc.rds_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds_ig.id
  }

  tags = {
    Name = "rds_route_table"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rds_route_table.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rds_route_table.id
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id      = aws_vpc.rds_vpc.id
  name        = "rds_security_group"
  description = "Allow inbound traffic to RDS"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all IPs (Update this to restrict access)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "rds_sg"
  }
}

# Subnet Group for RDS using new subnets
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

# Create the RDS PostgreSQL Database with version 12
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "12" # Update to the specific minor version of PostgreSQL 12 if needed
  instance_class         = "db.t3.micro"
  identifier             = "food-managed-by-terraform"
  db_name                = "food"     # The name of the database to create
  username               = "postgres" # The master username for the database
  password               = "postgres" # The master password for the database (Update to a secure password)
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  max_allocated_storage  = 100
  publicly_accessible    = true

  performance_insights_enabled = true

  deletion_protection = false

  tags = {
    Name = "food"
  }
}

# Output the RDS Endpoint
output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

# Output the RDS Username
output "rds_username" {
  value = aws_db_instance.postgres.username
}

# Output the RDS Database Name
output "rds_db_name" {
  value = aws_db_instance.postgres.db_name
}
