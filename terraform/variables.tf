variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "region" {
  default = "eu-north-1"
}

variable "frontend_bucket_name" {
  default = "project1-2-frontend"
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "ec2_instance_ip" {
  value = module.ec2_instance.public_ip
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
variable "datbase_vars" {
  type = map
    default =  {
          "DB_NAME" = "mydb",
          "DB_USER" = "dbuser",
          "DB_PASSWORD" = "mypassword",
          "DB_PORT" = "5432",

          "REDIS_PORT" = "6379",
          "REDIS_DB" = "0"
          "REDIS_PASSWORD" = "mypassword"
  }
}
