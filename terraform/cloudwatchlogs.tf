# cloudwatchlogs.tf

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# SNSの配信ステータスログを保存するCloudWatch Log Group
# SNSが自動作成する命名規則 (sns/<region>/<account_id>/<topic_name>) に合わせて事前に作成します。
resource "aws_cloudwatch_log_group" "sns_topic_log_group" {
  # sns.tf で定義されているaws_sns_topic.my_topic の name を参照
  name              = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/${aws_sns_topic.my_topic.name}"
  retention_in_days = 14 # ログの保存期間 (例: 14日)

  # aws_sns_topic リソースがこのロググループに依存しているため、
  # トピックが削除される前にこのロググループが削除されないようにライフサイクル設定を追加します。
  lifecycle {
    prevent_destroy = false
  }
}
