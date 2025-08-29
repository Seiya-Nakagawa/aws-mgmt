variable "aws_region" {
  description = "デプロイするAWSリージョン"
  type        = string
}

variable "system_name" {
  description = "システム識別子"
  type        = string
}

variable "env" {
  description = "環境識別子"
  type        = string
}

variable "sso_user_ids" {
  type        = list(string)
  description = "管理対象ユーザーリスト"
  default     = []
}

variable "aws_account_id" {
  description = "AWSアカウントID"
  type        = string
}

variable "slack_team_id" {
  description = "SlackチームID"
  type        = string
}

variable "slack_channel_id" {
  description = "SlackチャンネルID"
  type        = string
}

variable "notification_emails" {
  description = "通知を受け取るメールアドレスのリスト"
  type        = list(string)
  default     = []
}

variable "budget_amount" {
  description = "月間の予算額(USD)"
  type        = number
}

variable "budget_thresholds" {
  description = "予算アラートを通知するしきい値（パーセンテージ）のリスト"
  type        = list(number)
  default     = []
}

