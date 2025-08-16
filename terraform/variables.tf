variable "aws_region" {
  description = "デプロイするAWSリージョン"
  type        = string
}

variable "project_name" {
  description = "プロジェクト名。リソースのタグに使います。"
  type        = string
}

variable "env" {
  description = "プロジェクト名。リソースのタグに使います。"
  type        = string
}

variable "sso_user_names" {
  type        = list(string)
  description = "IAM Identity Centerで管理するユーザーのログイン名（@より前の部分）のリスト。このリストを元にSSMから情報を取得します。"
  default     = [] # デフォルトは空のリスト
}