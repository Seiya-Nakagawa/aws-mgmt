# AWS Personal Health Dashboard通知
# resource "aws_cloudwatch_event_rule" "event_rule_health" {
#   name        = "event-personal-health-dashboard"
#   event_pattern = <<EOF
# {
#   "source": [
#     "aws.health"
#   ]
# }
# EOF
#   tags = {
#     env  = "${var.env}"
#   }
# }

# resource "aws_cloudwatch_event_target" "event_target_health" {
#   rule      = aws_cloudwatch_event_rule.event_rule_health.id
#   arn       = aws_sns_topic.sns_topic_system.arn
# }

resource "aws_cloudwatch_event_rule" "evbrule_accessanaly" {
  name        = "${var.system_name}-${var.env}-evbrule-accessanaly"
  description = "Rule to notify when a new Access Analyzer finding is created"

  event_pattern = jsonencode({
    "source"      = ["aws.accessanalyzer"],
    "detail-type" = ["Access Analyzer Finding"]
  })

  tags = {
    Name       = "${var.system_name}-${var.env}-accessanalyzer-finding-rule",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_cloudwatch_event_target" "evbrule_target_sns_awschat" {
  rule      = aws_cloudwatch_event_rule.evbrule_accessanaly.name
  target_id = "SendToSNSTopic"
  arn       = aws_sns_topic.sns_topic_awschat.arn
}