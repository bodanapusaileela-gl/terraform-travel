# Terraform Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "us-east-2" # Change as per your region
}

# VPC and Subnet Setup
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a" # Adjust as needed

  tags = {
    Name = "my-private-subnet"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/ec2/my-instance"
  retention_in_days = 14
}

# IAM Role for EC2 to Access CloudWatch
resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach CloudWatch Policy to IAM Role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "my_instance" {
  ami           = "ami-00eb69d236edcfaf8" # Update with a valid AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.private.id

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "my-private-instance"
  }
}

# CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name                = "cpu-utilization-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "Alarm when CPU exceeds 80%"
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.my_topic.arn]
  ok_actions                = [aws_sns_topic.my_topic.arn]
  insufficient_data_actions = [aws_sns_topic.my_topic.arn]

  dimensions = {
    InstanceId = aws_instance.my_instance.id
  }
}

# SNS Topic for Alarm Notification
resource "aws_sns_topic" "my_topic" {
  name = "cloudwatch-alarm-topic"
}

# SNS Subscription for Email Notification
resource "aws_sns_topic_subscription" "my_email" {
  topic_arn = aws_sns_topic.my_topic.arn
  protocol  = "email"
  endpoint  = "bodanapusaileela1919@gmail.com" # Replace with your email
}

# Output Instance ID
output "instance_id" {
  value = aws_instance.my_instance.id
}
