module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.frontend_bucket_name

}

module "s3-bucket_object" {
  depends_on = [ module.s3_bucket ]
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"

  bucket = var.frontend_bucket_name
  file_source = "../frontend/index.html"
  key = "index.html"
  content_type = "html"
}