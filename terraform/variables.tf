# variables.tf

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