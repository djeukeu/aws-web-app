resource "aws_s3_bucket" "s3" {
  bucket        = "${var.app_name}-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 30

  tags = local.common_tags
}
