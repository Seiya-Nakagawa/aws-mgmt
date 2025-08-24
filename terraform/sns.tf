# sns.tf

# 既存または新規のSNSトピック
resource "aws_sns_topic" "my_topic" {
  name = "your-sns-topic-name" # ★ご自身のトピック名に変更してください

  # --- 配信ステータスのログ設定 ---
  # iam.tf で定義したロールを参照しています
  http_success_feedback_role_arn    = aws_iam_role.sns_delivery_status_logging_role.arn
  http_success_feedback_sample_rate = 100
  sqs_success_feedback_role_arn     = aws_iam_role.sns_delivery_status_logging_role.arn
  sqs_success_feedback_sample_rate  = 100
  lambda_success_feedback_role_arn  = aws_iam_role.sns_delivery_status_logging_role.arn
  lambda_success_feedback_sample_rate = 100
  
  http_failure_feedback_role_arn   = aws_iam_role.sns_delivery_status_logging_role.arn
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_delivery_status_logging_role.arn
  lambda_failure_feedback_role_arn = aws_iam_role.sns_delivery_status_logging_role.arn

  # cloudwatchlogs.tf で定義したロググループが作成された後に
  # このトピックが作成されるように、明示的な依存関係を設定します。
  depends_on = [
    aws_cloudwatch_log_group.sns_topic_log_group
  ]
}