data "aws_acm_certificate" "cert" {
  provider    = aws.us-east-1
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# S3
resource "aws_s3_bucket" "ketouem_com" {
  bucket        = var.domain_name
  acl           = "private"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "ketouem_com" {
  bucket = aws_s3_bucket.ketouem_com.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_from_cloudfront" {
  bucket = aws_s3_bucket.ketouem_com.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "AccessContentFromCloudFront",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.ketouem_com.arn}/*"
    },
    {
      "Sid": "2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.ketouem_com.arn}"
    }
  ]
}
EOF
}

# Cloudfront
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "CloudFront access to ${aws_s3_bucket.ketouem_com.id}"
}

resource "aws_cloudfront_distribution" "ketouem_com" {
  enabled             = true
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.ketouem_com.bucket_regional_domain_name
    origin_id   = "S3-${var.domain_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = "S3-${var.domain_name}"
    default_ttl            = 86400
    max_ttl                = 31536000
    min_ttl                = 0
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Warning: certificate must be in us-east-1
    acm_certificate_arn = data.aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}

# Route53
resource "aws_route53_zone" "primary" {
  name = "${var.domain_name}."
}

resource "aws_route53_record" "site_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${var.domain_name}."
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ketouem_com.domain_name
    zone_id                = aws_cloudfront_distribution.ketouem_com.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_record_www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "5"

  records = [var.domain_name]
}
