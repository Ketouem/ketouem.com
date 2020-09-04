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
  acl           = "public-read"
  force_destroy = false

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# Cloudfront
resource "aws_cloudfront_distribution" "ketouem_com" {
  enabled             = true
  aliases             = [var.domain_name]
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.ketouem_com.bucket_domain_name
    origin_id   = "S3-${var.domain_name}"
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
