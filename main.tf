terraform {
  backend "s3" {
    bucket         = "nik3n-tf-state-test-devops" # имя твоего S3-бакета под state
    key            = "ec2-wp/terraform.tfstate"   # путь/имя файла state в бакете
    region         = "eu-north-1"                 # регион бакета
    dynamodb_table = "tf-locks"                   # таблица для lock'ов
    encrypt        = true                         # шифрование state
  }
}

provider "aws" {
  region = "eu-north-1"
}
# 1) Получаем default VPC (куда вешаем SG)
data "aws_vpc" "default" {
  default = true
}

# 2) Security Group с нужными правилами
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH (22), HTTP (80), HTTPS (443)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Берём самую свежую Ubuntu 22.04 LTS (Jammy) в регионе eu-north-1
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu_22_04.id
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = "nik3n-key" # замени, если ключ у тебя называется иначе

  # Подключаем cloud-init (User Data) из файла
  user_data                   = file("${path.module}/cloud-init.yaml")
  user_data_replace_on_change = true

  tags = {
    Name = "nik3n-wp-server"
  }
}

# Удобные выводы после apply
output "public_ip" {
  value = aws_instance.web.public_ip
}

output "http_url" {
  value = "http://${aws_instance.web.public_ip}"
}
