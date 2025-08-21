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

variable "slack_channel_id" {
  description = "SlackチャンネルID"
  type        = string
}

variable "slack_workspace_id" {
  description = "SlackワークスペースID"
  type        = string
}