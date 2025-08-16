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

variable "sso_user_ids" {
  type        = list(string)
  description = "管理対象ユーザーリスト"
  default     = []
}