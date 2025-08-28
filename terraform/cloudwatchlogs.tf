# SNSの配信ステータスログ
resource "aws_cloudwatch_log_group" "sns_topic_system_log_group" {
  name              = "sns/${var.aws_region}/${var.aws_account_id}/${var.system_name}-${var.env}-sns-system"
  retention_in_days = 1
  tags = {
    Name            = "sns/${var.aws_region}/${var.aws_account_id}/${var.system_name}-${var.env}-sns-system",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}
