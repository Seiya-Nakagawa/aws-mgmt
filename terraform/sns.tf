resource "aws_sns_topic" "sns_topic_awschat" {
  name              = "${var.system_name}-${var.env}-sns-awschat"
  display_name      = "${var.system_name}-${var.env}-sns-awschat"
  kms_master_key_id = "alias/aws/sns"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })

  # --- 失敗時のログ設定 ---
  http_failure_feedback_role_arn   = aws_iam_role.sns_delivery_status_logging_role.arn
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_delivery_status_logging_role.arn
  lambda_failure_feedback_role_arn = aws_iam_role.sns_delivery_status_logging_role.arn

  # ロググループが先に作成されることを保証するための依存関係
  depends_on = [
    aws_cloudwatch_log_group.sns_topic_awschat_log_group
  ]

  tags = {
    Name            = "${var.system_name}-${var.env}-sns-awschat",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy_awschat" {
  arn    = aws_sns_topic.sns_topic_awschat.arn
  policy = data.aws_iam_policy_document.sns_topic_policy_document_awschat.json
}