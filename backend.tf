terraform {
  required_version = ">=0.12.0"

  /*  backend "s3" {
    region  = "us-east-2"
    profile = "default" # using profile instead of aws access keys
    bucket  = var.tf_state_s3_bucket
    key     = var.tf_state_s3_key
    dynamodb_table = var.tf_state_lock_tbl_name
    
    encrypt = true
  }*/

}


resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.tf_state_s3_bucket
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.tf_state_lock_tbl_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
