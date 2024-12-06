variable "AWS_ACCESS_KEY_ID" {
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "AWS_REGION" {
  type = string
}

variable "frontend_bucket_name" {
  type = string
}

variable "database_vars" {
  type = map(any)
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "ec2_instance_ip" {
  value = module.ec2_instance[0].public_ip
}
