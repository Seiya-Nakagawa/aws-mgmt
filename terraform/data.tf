# 手動で有効化したIAM Identity Centerインスタンスの情報を取得
data "aws_ssoadmin_instances" "sso_instances" {}

# var.sso_user_idsを元に、SSMから全ユーザー情報を一括で読み取る
data "aws_ssm_parameter" "user_params" {
  for_each = toset(flatten([
    for user_id in var.sso_user_ids : [
      "/sso/users/${user_id}/given_name",
      "/sso/users/${user_id}/family_name",
      "/sso/users/${user_id}/email",
      "/sso/users/${user_id}/group",
    ]
  ]))
  name = each.key
}

# 現在のAWS認証情報に基づき、アカウントID、ユーザーID、ARNを取得するデータソース
data "aws_caller_identity" "caller_identity" {}

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
        "events.amazonaws.com",
        "budgets.amazonaws.com"
      ]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.sns_topic_system.arn]
  }
}

# SNSトピックのKMSキーのポリシードキュメントを作成
data "aws_iam_policy_document" "sns_key_policy" {
  policy_id = "auto-sns-2"

  statement {
    sid = "Allow access through SNS for all principals in the account that are authorized to use SNS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.ap-northeast-1.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.aws_account_id]
    }
  }

  statement {
    sid = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow SNS to encrypt and decrypt messages for topics in this account"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:sns:ap-northeast-1:${var.aws_account_id}:*"]
    }
  }
}