# Chatbot用のCloudWatchロググループ
resource "aws_cloudwatch_log_group" "loggroup_chatbot" {
  provider          = aws.us-east-1
  name              = "/aws/chatbot/${var.system_name}-${var.env}-chatbot-slack"
  retention_in_days = 1
  tags = {
    Name            = "/aws/chatbot/${var.system_name}-${var.env}-chatbot-slack",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}

# SNSの配信ステータスログを保存するCloudWatch Log Group (aws_sns_topic.sns_topic_awschat用)
resource "aws_cloudwatch_log_group" "sns_topic_awschat_log_group" {
  name              = "sns/${var.aws_region}/${var.aws_account_id}/${var.system_name}-${var.env}-sns-chatbot"
  retention_in_days = 1
  tags = {
    Name            = "sns/${var.aws_region}/${var.aws_account_id}/${var.system_name}-${var.env}-sns-chatbot",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}
