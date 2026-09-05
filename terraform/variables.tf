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

variable "aws_account_id" {
  description = "AWSアカウントID"
  type        = string
}

variable "production_account_id" {
  description = "本番アカウントのAWSアカウントID（OrganizationAccountAccessRoleへのassume_role先）"
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

variable "admin_email" {
  description = "本番アカウントIAM Identity Center管理者ユーザーのメールアドレス"
  type        = string
  sensitive   = true
}

variable "admin_given_name" {
  description = "本番アカウントIAM Identity Center管理者ユーザーの名"
  type        = string
  sensitive   = true
}

variable "admin_family_name" {
  description = "本番アカウントIAM Identity Center管理者ユーザーの姓"
  type        = string
  sensitive   = true
}

variable "production_sso_instance_arn" {
  description = "本番アカウント直下で手動有効化したIAM Identity Center（アカウントインスタンス）のARN"
  type        = string
}

variable "production_identity_store_id" {
  description = "本番アカウント直下で手動有効化したIAM Identity Center（アカウントインスタンス）のIdentity Store ID"
  type        = string
}
