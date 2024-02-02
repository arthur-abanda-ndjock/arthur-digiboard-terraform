# digiboard
resource "aws_ecr_repository" "ecr" {
  name                 = "digiboard"
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    "Environment" = "Dev"
  }
}
