resource "aws_s3_bucket" "my-test-bucket-hassaan-one" {
  bucket        = var.bucketa
  force_destroy = true

  tags = {
    Name = "My bucket"
  }
}

resource "aws_s3_bucket" "my-test-bucket-dup" {
  bucket        = var.bucketb
  force_destroy = true

  tags = {
    Name = "My bucket - Duplicate"
  }
}