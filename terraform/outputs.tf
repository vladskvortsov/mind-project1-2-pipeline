variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "region" {
  type = string
}

variable "frontend_bucket_name" {
  type = string
}

variable "database_vars" {
  type = map
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "ec2_instance_ip" {
  value = module.ec2_instance[0].public_ip
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}