data "aws_caller_identity" "current" {}

data "terraform_remote_state" "tf-frontend" {
  backend = "s3"
  config = {
    bucket = "project1-2-resources"
    key    = "tf-frontend/terraform.tfstate"
    region = "eu-north-1"
  }
}




module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "key"
  create_private_key = true
}

resource "aws_iam_instance_profile" "ecr-pull-ssm-connect-instance-profile" {
  name = "ecr-pull-ssm-connect-instance-profile"
  role = aws_iam_role.ecr-pull-ssm-connect-role.name
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

resource "aws_iam_role" "ecr-pull-ssm-connect-role" {
  name               = "ecr-pull-ssm-connect-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecr-pull-ssm-connect-role-1" {
  role       = aws_iam_role.ecr-pull-ssm-connect-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr-pull-ssm-connect-role-2" {
  role       = aws_iam_role.ecr-pull-ssm-connect-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}


data "aws_iam_policy_document" "ec2-connect" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/user"] # ,"arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/ec2-connect/*"
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_role" "ec2-connect" {
  name               = "ec2-connect"
  assume_role_policy = data.aws_iam_policy_document.ec2-connect.json
}

resource "aws_iam_role_policy_attachment" "ec2-connect-1" {
  role       = aws_iam_role.ec2-connect.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"

}
resource "aws_iam_role_policy_attachment" "ec2-connect-2" {
  role       = aws_iam_role.ec2-connect.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceConnect"
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name  = "project1-2-backend"
  count = 1

  ami                         = "ami-08eb150f611ca277f"
  instance_type               = "t3.micro"
  key_name                    = module.key_pair.key_pair_name
  vpc_security_group_ids      = [module.ec2_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = resource.aws_iam_instance_profile.ecr-pull-ssm-connect-instance-profile.name
  associate_public_ip_address = true
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io docker-compose
    sudo snap install aws-cli --classic
    sudo aws configure set aws_access_key_id ${var.AWS_ACCESS_KEY_ID}
    sudo aws configure set aws_secret_access_key ${var.AWS_SECRET_ACCESS_KEY}
    sudo aws ecr get-login-password --region ${var.AWS_REGION} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com
    cd /home/ubuntu/
    echo "SECRET_KEY=my-secret-key
    DEBUG=False

    DB_NAME=${var.database_vars.DB_NAME}
    DB_USER=${var.database_vars.DB_USER}
    DB_PASSWORD=${var.database_vars.DB_PASSWORD}
    DB_HOST=postgres
    DB_PORT=${var.database_vars.DB_PORT}

    REDIS_HOST=redis
    REDIS_PORT=${var.database_vars.REDIS_PORT}
    REDIS_DB=${var.database_vars.REDIS_DB}
    REDIS_PASSWORD=${var.database_vars.REDIS_PASSWORD}

    CORS_ALLOWED_ORIGINS=http://${data.terraform_remote_state.tf-frontend.outputs.cloudfront_distribution_domain_name}" > vars.env

    echo '# version: '3.8'
    services:
      postgres:
        env_file:
        - vars.env
        image: postgres:13
        container_name: postgres
        environment:
            POSTGRES_DB: ${var.database_vars.DB_NAME}
            POSTGRES_USER: ${var.database_vars.DB_USER}
            POSTGRES_PASSWORD: ${var.database_vars.DB_PASSWORD}
        volumes:
        - postgres_data:/var/lib/postgresql/data
        ports:
        - "5432:5432"
        networks:
        - backend

      redis:
        env_file:
        - vars.env
        image: redis:6.2
        container_name: redis
        command: redis-server --requirepass ${var.database_vars.REDIS_PASSWORD}
        ports:
        - "6379:6379"
        networks:
        - backend

      backend_rds:
        env_file:
        - vars.env
        image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project1-2-rds-backend:latest
        container_name: backend_rds
        ports:
        - "8000:8000"
        networks:
        - backend
        entrypoint: ["sh", "-c", "sleep 10 && python manage.py runserver 0.0.0.0:8000"]

      backend_redis:
        env_file:
        - vars.env
        image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project1-2-redis-backend:latest
        container_name: backend_redis
        ports:
        - "8003:8003"
        networks:
        - backend
        entrypoint: ["sh", "-c", "sleep 10 && python manage.py runserver 0.0.0.0:8003"]

    volumes:
      postgres_data:
        driver: local

    networks:
      backend:
        driver: bridge' > docker-compose.yml
    docker-compose up -d
  EOT

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "local_file" "config_json" {
  filename = "../frontend/config.json"
  content  = <<EOF
    {
    "BACKEND_RDS_URL": "http://${module.ec2_instance[0].public_ip}:8000/test_connection/",
    "BACKEND_REDIS_URL": "http://${module.ec2_instance[0].public_ip}:8003/test_connection/"
    }
  EOF
}

module "s3-bucket_object-2" {
  depends_on = [resource.local_file.config_json]
  source     = "terraform-aws-modules/s3-bucket/aws//modules/object"

  bucket       = var.frontend_bucket_name
  file_source  = "../frontend/config.json"
  key          = "config.json"
  content_type = "json"
}