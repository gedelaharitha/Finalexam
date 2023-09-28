# Define the VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.50.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
}

# Create a Public Route Table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.my-vpc.id
}

# Create a Route to the Internet Gateway
resource "aws_route" "route-to-igw" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my-igw.id
}

# Create Subnets in AZ-1
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.50.1.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true  # Enable auto-assign public IP
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.50.2.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true  # Enable auto-assign public IP
}

# Create Subnets in AZ-2
resource "aws_subnet" "subnet_3" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.50.3.0/24"
  availability_zone       = "ca-central-1b"
  map_public_ip_on_launch = true  # Enable auto-assign public IP
}

resource "aws_subnet" "subnet_4" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.50.4.0/24"
  availability_zone       = "ca-central-1b"
  map_public_ip_on_launch = true  # Enable auto-assign public IP
}

# Associate Subnet-1 and Subnet-3 to the Public Route Table
resource "aws_route_table_association" "subnet_1_association" {
  subnet_id      = aws_subnet.subnet_az1_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet_3_association" {
  subnet_id      = aws_subnet.subnet_az2_1.id
  route_table_id = aws_route_table.public.id
}


# Initialize the AWS provider
provider "aws" {
  region = "ca-central-1" 
}

# Create an S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "harithabucket"  
  acl    = "private"
}

# Create an IAM Role
resource "aws_iam_role" "my_role" {
  name = "my-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM Policy
resource "aws_iam_policy" "my_policy" {
  name = "my-policy"

  description = "Sample IAM Policy for Glue Job"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = ["arn:aws:s3:::my-unique-bucket-name/*"]
      }
    ]
  })
}

# Attach the IAM Policy to the IAM Role
resource "aws_iam_policy_attachment" "attach_policy" {
  policy_arn = aws_iam_policy.my_policy.arn
  roles      = [aws_iam_role.my_role.name]
}

# Create a Security Group
resource "aws_security_group" "my_sg" {
  name_prefix        = "my-sg"
  description        = "Security Group for RDS"
  vpc_id             = "my-vpc"
}

# Create a Security Group Rule to allow inbound traffic on port 3306 RDS
resource "aws_security_group_rule" "my_sg_rule" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_sg.id
}

# Create an RDS Instance
resource "aws_db_instance" "my_db_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "my-db-instance"
  username             = "admin"
  password             = "MySecurePassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.my_sg.id]
}

# Create an AWS Glue Job
resource "aws_glue_job" "my_glue_job" {
  name          = "my-glue-job"
  role          = aws_iam_role.my_role.arn
  command {
    name        = "pythonshell"
    python_version = "3"
    script_uri  = "s3://harithabucket/glue-script.py"  
  }
}

# Create a KMS Key
resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS Key"
  deletion_window_in_days = 30
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet_1", "subnet_2"]  
}

# Create an AutoScaling Group
resource "aws_autoscaling_group" "my_asg" {
  name = "my-asg"

  min_size = 2
  max_size = 5

  launch_template {
    id = "your-launch-template-id"  
  }

  vpc_zone_identifier = ["subnet_1", "subnet_2"]  
}
