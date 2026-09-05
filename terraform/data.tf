# 手動で有効化したIAM Identity Centerインスタンスの情報を取得
data "aws_ssoadmin_instances" "sso_instances" {}

# 現在のAWS認証情報に基づき、アカウントID、ユーザーID、ARNを取得するデータソース
data "aws_caller_identity" "caller_identity" {}

# --- User Data ---
# ユーザー情報を格納した単一のSSMパラメータを読み込む
data "aws_ssm_parameter" "users" {
  name            = "/org/sso/users"
  with_decryption = true
}

# --- Other Data Sources ---

# SNSトピックのポリシードキュメントを作成
data "aws_iam_policy_document" "sns_topic_policy_document_system" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.sns_topic_system.arn]
  }
}