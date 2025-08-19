# ----------------------------------------------------------------
# CloudTrail 組織証跡
# ----------------------------------------------------------------
resource "aws_cloudtrail" "organization_trail" {
  name                          = var.trail_name
  # s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true

  tags = {
    Name = var.trail_name
  }

  # aws_kms_key_policyが先に作成されることを保証
  depends_on = [aws_kms_key_policy.cloudtrail_key_policy]
}