module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "project1-2-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

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
  vpc_id      = module.vpc.default_vpc_id

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

