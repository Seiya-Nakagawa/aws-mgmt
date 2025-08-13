# variables.tf

variable "aws_region" {
  description = "デプロイするAWSリージョン"
  type        = string
}

variable "project_name" {
  description = "プロジェクト名。リソースのタグに使います。"
  type        = string
}

# variable "bucket_name" {
#   description = "作成するS3バケットの名前（グローバルで一意である必要があります）"
#   type        = string
# }