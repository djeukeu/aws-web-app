resource "aws_s3_bucket" "s3" {
  bucket        = "${var.app_name}-lb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = var.app_name
  retention_in_days = 30
}
