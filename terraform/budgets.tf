resource "aws_budgets_budget" "total" {
  name         = "${var.system_name}-${var.env}-budget-total"
  budget_type  = "COST"
  limit_amount = var.budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Organizations全体を対象とするため、cost_filtersは設定しない

  dynamic "notification" {
    for_each = toset(var.budget_thresholds)
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL" # 実績値がしきい値を超えた場合に通知
      subscriber_sns_topic_arns = [aws_sns_topic.sns_topic_system.arn]
    }
  }

  tags = {
    Name       = "${var.system_name}-${var.env}-budget-total",
    SystemName = var.system_name,
    Env        = var.env,
  }
}
