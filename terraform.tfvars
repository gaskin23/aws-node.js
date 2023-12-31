vpc_cidr_block              = "90.90.0.0/16"
Public1a                    = "90.90.10.0/24"
Public1b                    = "90.90.20.0/24"
Private1a                   = "90.90.11.0/24"
Private1b                   = "90.90.21.0/24"
env_prefix                  = "Capstone"
AZ_1A                       = "us-east-1a"
AZ_1B                       = "us-east-1b"
instance_type               = "t3.medium"
key_name                    = "config-admin"
image_id                    = "ami-0e472ba40eb589f49"
LT_resource_type            = "instance"
nat_ami                     = "ami-00a9d4a05375b2763"
db_subnet                   = "rds_subnet"
db_instance_identifier      = "aws-nodejs-rds"
db_engine                   = "postgres"
db_engine_version           = "15.3"
db_instance_class           = "db.r6g.large"
db_backup_window            = "01:00-02:00"
db_maintenance_window       = "Mon:02:00-Mon:03:00"
db_name                     = "config_data"
db_username                 = "xxxxxxxx"
db_password                 = "xxxxxxxxxx"
db_parameter_group_name     = "default.postgres15"
db_port                     = "3306"
db_allocated_storage        = "20"
db_max_allocated_storage    = "40"
db_backup_retention_period  = "7"
load_balancer_type          = "application"
lb_target_type              = "instance"
listener_http_type          = "forward"
listener_https_type         = "forward"
ASG_health_check_type       = "ELB"
aws_bucket                 = "aws-node.js"
aws_acl                     = "public-read"
s3_object_key               = "index.html"
s3_object_key2              = "sorry.jpg"
blog_acl                    = "public-read"
blog_bucket                 = "awscapstonesgaskinblog"
blog_index_document         = "index.html"
cf_origin_protocol_policy   = "match-viewer"
cf_origin_ssl_protocols     = ["TLSv1.2"]
cf_allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
cf_cached_methods           = ["GET", "HEAD", "OPTIONS"]
cf_viewer_protocol_policy   = "redirect-to-https"
cf_path_pattern             = "media/*.jpg"
cf_forward                  = "all"
cf_price_class              = "PriceClass_All"
cf_restriction_type         = "none"
cf_ssl_support_method       = "sni-only"
cf_minimum_protocol_version = "TLSv1.2_2021"