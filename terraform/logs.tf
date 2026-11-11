resource "aws_s3_bucket" "s3" {
  # checkov:skip=CKV2_AWS_62:Event notifications are not part of the current ALB access log bucket design.
  # checkov:skip=CKV2_AWS_61:Log retention lifecycle has not been configured for this bucket.
  # checkov:skip=CKV2_AWS_6:Public access is not intended; bucket access is constrained by its policy and ALB log delivery.
  # checkov:skip=CKV_AWS_18:Logging this log bucket to itself would create recursive logging; a separate destination bucket is not configured.
  # checkov:skip=CKV_AWS_144:Cross-region replication is not configured for this deployment's access logs.
  # checkov:skip=CKV_AWS_145:The bucket uses S3-managed encryption; a customer-managed KMS key is not configured.
  bucket        = "${var.app_name}-lb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  # checkov:skip=CKV_AWS_338:Only used for logging, only 30 days retention is needed
  # checkov:skip=CKV_AWS_158:KMS is not needed for logging; no sensitive data is stored in these logs.
  name              = var.app_name
  retention_in_days = 30
}
