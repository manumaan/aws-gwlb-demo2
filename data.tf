#get AMI ID for Amazon Linux 2023 in current region
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.5.20240722.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

output "ami_id" {
  value = data.aws_ami.amazon_linux.id
}


# Get the availability zones in the current region
data "aws_availability_zones" "available" {}

