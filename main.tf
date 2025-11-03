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
