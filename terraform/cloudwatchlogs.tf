# cloudwatchlogs.tf

# Chatbot用のCloudWatchロググループ
resource "aws_cloudwatch_log_group" "loggroup_chatbot" {
  name              = "/aws/chatbot/chat-configurations/${aws_chatbot_slack_channel_configuration.chatbot_slack.name}"
  retention_in_days = 1
  tags = {
    Name            = "/aws/chatbot/chat-configurations/${aws_chatbot_slack_channel_configuration.chatbot_slack.name}",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}

# SNSの配信ステータスログを保存するCloudWatch Log Group (aws_sns_topic.sns_topic_awschat用)
resource "aws_cloudwatch_log_group" "sns_topic_awschat_log_group" {
  name              = "sns/${var.aws_region}/${var.aws_account_id}/${aws_sns_topic.sns_topic_awschat.name}"
  retention_in_days = 1
  tags = {
    Name            = "sns/${var.aws_region}/${var.aws_account_id}/${aws_sns_topic.sns_topic_awschat.name}",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}