//////////////DB-SUBNET/////////

resource "aws_db_subnet_group" "rds_subnet" {
  name       = var.db_subnet
  subnet_ids = [aws_subnet.Private1A.id, aws_subnet.Private1B.id]

}

//////////////DB-INSTANCE///////////
resource "aws_db_instance" "postgresql" {
  identifier              = var.db_instance_identifier
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  storage_type            = "gp2"
  engine                  = var.db_engine 
  engine_version          = var.db_engine_version 
  instance_class          = var.db_instance_class
  name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = var.db_parameter_group_name
  skip_final_snapshot     = true
  apply_immediately       = true
  vpc_security_group_ids  = [aws_security_group.RDS-sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet.id
  publicly_accessible     = false
  port                    = var.db_port
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window

  tags = {
    Name = "${var.env_prefix}-RDS-instance"
  }
}

////////////////S3-BUCKET/////////////

resource "aws_s3_bucket" "aws-bucket" {
  bucket        = var.aws_bucket
  force_destroy = true
}

/////////////NAT-INSTANCE/////////
resource "aws_instance" "Capstone-NAT-instance" {
  ami                         = var.nat_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.Public1A.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.NAT-sg.id]
  source_dest_check           = false
  key_name                    = var.key_name

  tags = {
    Name = "${var.env_prefix}-NAT-instance"
  }

}

/////////////////LAUNCH-TEMPLATE///////////

resource "aws_launch_template" "Capstone-LT" {
  name                    = "${var.env_prefix}-LT"
  image_id                = var.image_id
  instance_type           = var.instance_type
  key_name                = var.key_name
  disable_api_termination = true
  iam_instance_profile {
    name = aws_iam_instance_profile.EC2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.WebServer-sg.id]
  }


  tag_specifications {
    resource_type = var.LT_resource_type
    tags = {
      Name = "${var.env_prefix}-LT"
    }
  }

  user_data = filebase64("user_data.sh")

}

//////////////IAM-ROLE/////////////

resource "aws_iam_role" "aws_capstone_EC2_S3_Full_Access" {
  name               = "${var.env_prefix}-EC2-S3-Fullaccess"
  assume_role_policy = file("assumerolepolicy.json")
}

resource "aws_iam_instance_profile" "EC2_profile" {
  name = "${var.env_prefix}-profile2"
  role = aws_iam_role.aws_capstone_EC2_S3_Full_Access.name
}

resource "aws_iam_policy" "S3-Policy" {
  name   = "${var.env_prefix}-EC2-S3-policy"
  policy = file("policys3bucket.json")
}

resource "aws_iam_policy_attachment" "role-attach" {
  name       = "${var.env_prefix}-s3-role-attach"
  roles      = ["${aws_iam_role.aws_capstone_EC2_S3_Full_Access.name}"]
  policy_arn = aws_iam_policy.S3-Policy.arn
}

# #/////////////////AMAZON CERTIFICATE MANAGER///////////

# data "aws_acm_certificate" "amazon_issued" {
#   domain      = var.acm_domain
#   types       = var.acm_types
#   most_recent = true
# }

///ELASTIC LOAD BALANCER/////

resource "aws_lb_target_group" "Capstone-tg" {
  vpc_id           = aws_vpc.Capstone-VPC.id
  name             = "${var.env_prefix}-tg"
  target_type      = var.lb_target_type
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"

  health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 20
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb" "Capstone-ELB" {
  name               = "${var.env_prefix}-ELB"
  internal           = false
  load_balancer_type = var.load_balancer_type
  security_groups    = [aws_security_group.ELB-sg.id]
  subnets            = [aws_subnet.Public1A.id, aws_subnet.Public1B.id]
}

resource "aws_lb_listener" "Capstone-listener-80" {
  load_balancer_arn = aws_lb.Capstone-ELB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = var.listener_http_type
    target_group_arn = aws_lb_target_group.Capstone-tg.arn
  }
}

# resource "aws_lb_listener" "Capstone-listener-443" {
#   load_balancer_arn = aws_lb.Capstone-ELB.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = data.aws_acm_certificate.amazon_issued.arn

#   default_action {
#     type             = var.listener_https_type
#     target_group_arn = aws_lb_target_group.Capstone-tg.arn
#   }
# }

#//////////////////AUTO SCALING GROUP///////////////

resource "aws_autoscaling_group" "Capstone-asg" {
  vpc_zone_identifier       = [aws_subnet.Private1A.id, aws_subnet.Private1B.id]
  health_check_type         = var.ASG_health_check_type
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.Capstone-tg.arn]

  launch_template {
    id      = aws_launch_template.Capstone-LT.id
    version = "$Latest"

    network_interfaces {
    associate_public_ip_address = true
  }

  }
}

/////////cloudfront distrubition/////////

resource "aws_cloudfront_distribution" "aws-capstone-elb" {
  origin {
    domain_name = aws_lb.Capstone-ELB.dns_name
    origin_id   = "Capstone-ELB"
  }

  enabled = true

  default_cache_behavior {
    target_origin_id = "Capstone-ELB"
    viewer_protocol_policy = "allow-all"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
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
# resource "aws_cloudfront_distribution" "Capstone-ELB-cloudfront" {
#   origin {
#     domain_name = aws_lb.Capstone-ELB.dns_name
#     origin_id   = aws_lb.Capstone-ELB.dns_name

#   }

#   enabled = true
#   comment = "${var.env_prefix}-CF-ELB"

#   default_cache_behavior {
#     compress         = true
#     allowed_methods  = var.cf_allowed_methods
#     cached_methods   = var.cf_cached_methods
#     target_origin_id = aws_lb.Capstone-ELB.dns_name
#     viewer_protocol_policy = "allow-all" 
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400

#     forwarded_values {
#       query_string            = false
#       headers                 = ["*"]
#       query_string_cache_keys = []

#       cookies {
#         forward = var.cf_forward
#       }
#     }
#   }

#   price_class = var.cf_price_class
#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = var.cf_restriction_type
#     }
#   }
# }

////////ROUTE53 DNS ////////////////////

# resource "aws_route53_health_check" "Capstone-health-check" {
#   fqdn              = aws_cloudfront_distribution.Capstone-ELB-cloudfront.domain_name
#   port              = 80
#   type              = var.rt53_type
#   resource_path     = var.rt53_resource_path
#   failure_threshold = var.rt53_failure_threshold
#   request_interval  = var.rt53_request_interval

#   tags = {
#     Name = "${var.env_prefix}-route53-hc"
#   }
# }
# #///////////////data hosted zone////////////////
# data "aws_route53_zone" "Capstone-hosted-zone" {
#   name         = var.domain_name
#   private_zone = false
# }

# #////////////////records//////////

# resource "aws_route53_record" "route53-primary" {
#   zone_id        = data.aws_route53_zone.Capstone-hosted-zone.zone_id
#   name           = "www.${data.aws_route53_zone.Capstone-hosted-zone.name}"
#   type           = var.rt53_record_type
#   set_identifier = var.rt53_set_identifier

#   aws_routing_policy {
#     type = var.rt53_aws_type
#   }

#   alias {
#     name                   = aws_cloudfront_distribution.Capstone-ELB-cloudfront.domain_name
#     zone_id                = aws_cloudfront_distribution.Capstone-ELB-cloudfront.hosted_zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "route53-secondary" {
#   zone_id        = data.aws_route53_zone.Capstone-hosted-zone.zone_id
#   name           = var.domain_name
#   type           = var.rt53_record_type
#   set_identifier = var.rt53_aws_type

#   aws_routing_policy {
#     type = var.rt53_aws_secondary_type
#   }
#   alias {
#     name                   = aws_s3_bucket.aws-bucket.website_domain
#     zone_id                = aws_s3_bucket.aws-bucket.hosted_zone_id
#     evaluate_target_health = false
#   }
# }