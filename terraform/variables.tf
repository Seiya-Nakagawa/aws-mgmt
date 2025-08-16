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

variable "sso_users" {
  type = map(object({
    display_name = string
    given_name   = string # 名
    family_name  = string # 姓
    email        = string # 通知用メールアドレス
  }))
  description = "IAM Identity Centerに作成する全ユーザーのマップ。マップのキーがログインユーザー名(user_name)になります。"

  # ユーザー情報は機密情報
  sensitive = true
  
  # デフォルト値を空のマップにしておくと、ユーザーがいない場合でもエラーにならない
  default = {}
}