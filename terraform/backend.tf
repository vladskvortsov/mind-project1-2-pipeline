data "aws_caller_identity" "current" {}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "project1-2-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "prod"
  }
}

module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "ec2_sg"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules            = ["http-80-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      from_port   = 8000
      to_port     = 8000
      from_port   = 8003
      to_port     = 8003
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}


module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = "key"
  create_private_key = true
}


resource "aws_iam_instance_profile" "ecr-pull-instance-profile" {
  name = "ecr-pull-instance-profile"
  role = aws_iam_role.ecr-pull-role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecr-pull-role" {
  name               = "ecr-pull-role"
  path               = "../ecr-pull-role.json"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "1.7.0"

  name           = "project1-2-backend"
  count = 1

  ami                    = "ami-08eb150f611ca277f"
  instance_type          = "t3.micro"
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [ module.ec2_sg.security_group_id ]
  subnet_id              = module.vpc.private_subnets
  iam_instance_profile   = resource.aws_iam_instance_profile.ecr-pull-instance-profile.name
  associate_public_ip_address = true
  user_data              = <<EOF
          #!/bin/bash
          sudo apt update -y
          sudo apt install -y docker.io docker-compose
          sudo snap install aws-cli --classic
          sudo aws configure set aws_access_key_id ${var.access_key}
          sudo aws configure set aws_secret_access_key ${var.secret_key}
          sudo aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
          cd /home/ubuntu/
          echo "SECRET_KEY=my-secret-key
          DEBUG=False

          DB_NAME=${var.datbase_vars.DB_NAME}
          DB_USER=${DB_USER}
          DB_PASSWORD=${var.datbase_vars.DB_PASSWORD}
          DB_HOST=postgres
          DB_PORT=${var.datbase_vars.DB_PORT}

          REDIS_HOST=redis
          REDIS_PORT=${var.datbase_vars.REDIS_PORT}
          REDIS_DB=${var.datbase_vars.REDIS_DB}
          REDIS_PASSWORD=${var.datebase_vars.REDIS_PASSWORD}

          CORS_ALLOWED_ORIGINS=http://${module.cloudfront.cloudfront_distribution_domain_name}" > vars.env

          echo '# version: '3.8'
          services:
            postgres:
              env_file:
                - .env
              image: postgres:13
              container_name: postgres
              environment:
                POSTGRES_DB: ${DB_NAME}
                POSTGRES_USER: ${DB_USER}
                POSTGRES_PASSWORD: ${DB_PASSWORD}
              volumes:
                - postgres_data:/var/lib/postgresql/data
              ports:
                - "5432:5432"
              networks:
                - backend

            redis:
              env_file:
                - .env
              image: redis:6.2
              container_name: redis
              environment:
                REDIS_PASSWORD: ${REDIS_PASSWORD}
              command: redis-server --requirepass ${REDIS_PASSWORD}
              ports:
                - "6379:6379"
              networks:
                - backend

            backend_rds:
              env_file:
              - vars.env
              image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/project1-2-backend:backend-rds
              container_name: backend_rds
              ports:
                - "8000:8000"
              networks:
                - backend
              entrypoint: ["sh", "-c", "sleep 10 && python manage.py runserver 0.0.0.0:8000"]

            backend_redis:
              env_file:
              - vars.env
              image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/project1-2-backend:backend-redis
              container_name: backend_redis
              ports:
                - "8003:8003"
              networks:
                - backend
              entrypoint: ["sh", "-c", "sleep 10 && python manage.py runserver 0.0.0.0:8003"]

          networks:
            backend:
              driver: bridge' > docker-compose.yml
          docker-compose up -d
  EOF

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "local_file" "config_json" {
  filename = "../frontend/config.json"
  content = <<EOF
              {
                "BACKEND_RDS_URL": "http://${module.ec2_instance.public_ip}:8000/test_connection/",
                "BACKEND_REDIS_URL": "http://${module.ec2_instance.public_ip}:8003/test_connection/"
              }
              EOF
}
module "s3-bucket_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.2.2"

  bucket = var.frontend_bucket_name
  content = "../frontend/config.json"

}