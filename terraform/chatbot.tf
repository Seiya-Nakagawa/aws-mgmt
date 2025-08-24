# resource "aws_chatbot_slack_channel_configuration" "chatbot_slack" {
#   slack_team_id      = var.slack_team_id
#   slack_channel_id   = var.slack_channel_id
#   configuration_name = "${var.system_name}-${var.env}-chatbot-slack"
#   iam_role_arn       = aws_iam_role.iamrole_chatbot.arn
#   sns_topic_arns     = [aws_sns_topic.sns_topic_awschat.arn]

#   # ログレベルを設定 (ERROR, INFO, NONE)
#   logging_level = "ERROR" 
#   depends_on = [aws_cloudwatch_log_group.loggroup_chatbot]
# }