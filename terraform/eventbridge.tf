# Personal Health Dashboard監視用ルール
resource "aws_cloudwatch_event_rule" "evbrule_health" {
  name        = "${var.system_name}-${var.env}-evbrule-health"
  description = "Rule to notify AWS Personal Health Dashboard events"

  event_pattern = jsonencode({
    source = ["aws.health"]
  })

  tags = {
    Name       = "${var.system_name}-${var.env}-health-event-rule",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_cloudwatch_event_target" "evbrule_target_health_sns_system" {
  rule      = aws_cloudwatch_event_rule.evbrule_health.name
  target_id = "SendToSNSTopicForHealth"
  arn       = aws_sns_topic.sns_topic_system.arn
}

# Access Analyzer監視用ルール
resource "aws_cloudwatch_event_rule" "evbrule_accessanaly" {
  name        = "${var.system_name}-${var.env}-evbrule-accessanaly"
  description = "Rule to notify when a new Access Analyzer finding is created"

  event_pattern = jsonencode({
    "source"      = ["aws.access-analyzer"],
    "detail-type" = ["Access Analyzer Finding"]
  })

  tags = {
    Name       = "${var.system_name}-${var.env}-accessanalyzer-finding-rule",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_cloudwatch_event_target" "evbrule_target_sns_system" {
  rule      = aws_cloudwatch_event_rule.evbrule_accessanaly.name
  target_id = "SendToSNSTopicForSystem"
  arn       = aws_sns_topic.sns_topic_system.arn
}