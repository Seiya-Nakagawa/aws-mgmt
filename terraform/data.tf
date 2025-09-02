# 手動で有効化したIAM Identity Centerインスタンスの情報を取得
data "aws_ssoadmin_instances" "sso_instances" {}

# 現在のAWS認証情報に基づき、アカウントID、ユーザーID、ARNを取得するデータソース
data "aws_caller_identity" "caller_identity" {}

# --- Account Data ---
# アカウントIDのリストをSSMから取得
data "aws_ssm_parameter" "accounts_list" {
  name = "/org/accounts-list"
}

# 各アカウントIDに対応する詳細情報(SecureString)をSSMから取得
data "aws_ssm_parameter" "accounts" {
  for_each        = toset(split(",", data.aws_ssm_parameter.accounts_list.value))
  name            = "/org/accounts/${each.key}"
  with_decryption = true
}

# --- User Data ---
# ユーザーIDのリストをSSMから取得
data "aws_ssm_parameter" "users_list" {
  name = "/org/sso/users-list"
}

# 各ユーザーIDに対応する詳細情報(SecureString)をSSMから取得
data "aws_ssm_parameter" "users" {
  for_each        = toset(split(",", data.aws_ssm_parameter.users_list.value))
  name            = "/org/sso/users/${each.key}"
  with_decryption = true
}

# --- Other Data Sources ---
# 本番OU に所属する全メンバーアカウントの情報を取得
data "aws_organizations_organizational_unit_child_accounts" "prd_accounts_list" {
  parent_id = aws_organizations_organizational_unit.ou_prd.id
}

# 開発OUに所属する全メンバーアカウントの情報を取得
data "aws_organizations_organizational_unit_child_accounts" "dev_accounts_list" {
  parent_id = aws_organizations_organizational_unit.ou_dev.id
}

# SNSトピックのポリシードキュメントを作成
data "aws_iam_policy_document" "sns_topic_policy_document_system" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.sns_topic_system.arn]
  }
}