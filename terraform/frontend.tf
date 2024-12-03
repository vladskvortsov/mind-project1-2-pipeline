module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.frontend_bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

}

module "s3-bucket_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.2.2"

  bucket = var.frontend_bucket_name
  content = "../frontend/*"
}












module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"

#   aliases = ["cdn.example.com"]

  enabled             = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "${var.frontend_bucket_name}.s3.amazonaws.com"
  }

  origin = {
    s3_origin = {
      domain_name = "${var.frontend_bucket_name}.s3.amazonaws.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    s3_one = {
      domain_name = "${var.frontend_bucket_name}.s3.amazonaws.com"
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id           = "s3_origin"
    viewer_protocol_policy     = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/index.html"
      target_origin_id       = "s3_origin"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:135367859851:certificate/1032b155-22da-4ae0-9f69-e206f825458b"
    ssl_support_method  = "sni-only"
  }
}