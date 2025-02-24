terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "sa-east-1"
}

##################
# S3 Bucket
##################
resource "aws_s3_bucket" "cartao_visita" {
  bucket = "meu-bucket-cartao-visita"
}

resource "aws_s3_bucket_public_access_block" "cartao_visita_public" {
  bucket                  = aws_s3_bucket.cartao_visita.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.cartao_visita.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.cartao_visita.id
  policy = data.aws_iam_policy_document.public_read_policy.json
}

data "aws_iam_policy_document" "public_read_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cartao_visita.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

##################
# CloudFront
##################
resource "aws_cloudfront_distribution" "cdn_cartao_visita" {
  origin {
    domain_name = aws_s3_bucket.cartao_visita.bucket_regional_domain_name
    origin_id   = "S3-meu-bucket-cartao-visita"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-meu-bucket-cartao-visita"
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = 3600
    max_ttl     = 86400
    min_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

output "cloudfront_domain_name" {
  description = "Business Card URL"
  value       = aws_cloudfront_distribution.cdn_cartao_visita.domain_name
}
