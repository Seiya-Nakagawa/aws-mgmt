# 本番アカウント直下に構築するアカウントレベルの統制・監視リソース
#
# 本番アカウントが組織のメンバーである間、OrganizationAccountAccessRoleへのassume_roleで
# 本番アカウント側にリソースを構築する（provider = aws.production）。
# CloudTrailはデフォルトのEvent history（直近90日）を利用する方針のため、専用のTrail・
# S3ログ保管は構築しない。

# Access Analyzer（本番アカウント単体のアカウントタイプ）
resource "aws_accessanalyzer_analyzer" "accessanaly_production" {
  provider = aws.production

  analyzer_name = "${var.system_name}-${var.env}-accessanaly-prd"
  type          = "ACCOUNT"

  tags = {
    Name       = "${var.system_name}-${var.env}-accessanaly-prd",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

# 通知用SNSトピック
resource "aws_sns_topic" "sns_topic_system_production" {
  provider = aws.production

  name         = "${var.system_name}-${var.env}-sns-system-prd"
  display_name = "${var.system_name}-${var.env}-sns-system-prd"

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
}

resource "aws_sns_topic_policy" "sns_topic_policy_system_production" {
  provider = aws.production

  arn    = aws_sns_topic.sns_topic_system_production.arn
  policy = data.aws_iam_policy_document.sns_topic_policy_document_production.json
}

resource "aws_sns_topic_subscription" "email_target_production" {
  provider = aws.production
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.sns_topic_system_production.arn
  protocol  = "email"
  endpoint  = each.value
}

# コスト監視
resource "aws_budgets_budget" "total_production" {
  provider = aws.production

  name         = "${var.system_name}-${var.env}-budget-total-prd"
  budget_type  = "COST"
  limit_amount = var.budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  dynamic "notification" {
    for_each = toset(var.budget_thresholds)
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.notification_emails
    }
  }

  tags = {
    Name       = "${var.system_name}-${var.env}-budget-total-prd",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

# Personal Health Dashboard監視用ルール
resource "aws_cloudwatch_event_rule" "evbrule_health_production" {
  provider = aws.production

  name        = "${var.system_name}-${var.env}-evbrule-health-prd"
  description = "Rule to notify AWS Personal Health Dashboard events"

  event_pattern = jsonencode({
    source = ["aws.health"]
  })

  tags = {
    Name       = "${var.system_name}-${var.env}-evbrule-health-prd",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_cloudwatch_event_target" "evbrule_target_health_sns_production" {
  provider = aws.production

  rule      = aws_cloudwatch_event_rule.evbrule_health_production.name
  target_id = "SendToSNSTopicForHealth"
  arn       = aws_sns_topic.sns_topic_system_production.arn
}

# Access Analyzer監視用ルール
resource "aws_cloudwatch_event_rule" "evbrule_accessanaly_production" {
  provider = aws.production

  name        = "${var.system_name}-${var.env}-evbrule-accessanaly-prd"
  description = "Rule to notify when a new Access Analyzer finding is created"

  event_pattern = jsonencode({
    "source"      = ["aws.access-analyzer"],
    "detail-type" = ["Access Analyzer Finding"]
  })

  tags = {
    Name       = "${var.system_name}-${var.env}-evbrule-accessanaly-prd",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_cloudwatch_event_target" "evbrule_target_sns_production" {
  provider = aws.production

  rule      = aws_cloudwatch_event_rule.evbrule_accessanaly_production.name
  target_id = "SendToSNSTopicForSystem"
  arn       = aws_sns_topic.sns_topic_system_production.arn
}

# Trusted Advisor監視用ルール
resource "aws_cloudwatch_event_rule" "evbrule_trustedadvisor_production" {
  provider = aws.production

  name        = "${var.system_name}-${var.env}-evbrule-trustedadvisor-prd"
  description = "Rule to notify AWS Trusted Advisor events"

  event_pattern = jsonencode({
    source = ["aws.trustedadvisor"],
  })

  tags = {
    Name       = "${var.system_name}-${var.env}-evbrule-trustedadvisor-prd",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_cloudwatch_event_target" "evbrule_target_trustedadvisor_sns_production" {
  provider = aws.production

  rule      = aws_cloudwatch_event_rule.evbrule_trustedadvisor_production.name
  target_id = "SendToSNSTopicForSystem"
  arn       = aws_sns_topic.sns_topic_system_production.arn
}
