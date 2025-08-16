# 手動で有効化したSSOインスタンスの情報を取得
data "aws_ssoadmin_instances" "admin_sso_instances" {}

locals {
  # 読み込んだSSOインスタンスのARNをローカル変数に格納
  # one()関数は、リストの要素が一つだけであることを保証し、その要素を返す安全な方法
  sso_instance_arn = one(data.aws_ssoadmin_instances.admin_sso_instances.arns)
}

# 組織管理用許可セット
resource "aws_ssoadmin_permission_set" "admin_ssopermsets_administrator" {
  name                = "${var.project_name}-${var.env}-ssopermsets-admin"
  description         = "Permission set for administrators"
  instance_arn        = local.sso_instance_arn
  session_duration    = "PT4H" # 4時間
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_ssopermsets_administrator_policy" {
  instance_arn       = aws_ssoadmin_permission_set.admin_ssopermsets_administrator.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_ssopermsets_administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 開発者用許可セット
resource "aws_ssoadmin_permission_set" "admin_ssopermsets_developer" {
  name             = "${var.project_name}-${var.env}-ssopermsets-developer"
  description      = "Permission set for developers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 4時間
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_ssopermsets_developer_policy" {
  instance_arn       = aws_ssoadmin_permission_set.admin_ssopermsets_developer.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_ssopermsets_developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

#-------------------------------------------------
# グループとユーザー (Groups and Users)
#-------------------------------------------------

# 管理者グループ
resource "aws_identitystore_group" "administrators" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.project_name}-${var.env}-administrators"
  description       = "Administrators group"
}

# 開発者グループ
resource "aws_identitystore_group" "developers" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.project_name}-${var.env}-developers"
  description       = "Developers group"
}

# # ユーザーの作成 (例)
# resource "aws_identitystore_user" "user_a" {
#   identity_store_id = local.identity_store_id
#   display_name      = "Taro Yamada"
#   user_name         = "taro.yamada@example.com" # ログイン時のユーザー名

#   name {
#     given_name  = "Taro"
#     family_name = "Yamada"
#   }

#   emails {
#     value   = "taro.yamada@example.com" # 通知などが送信されるメールアドレス
#     primary = true
#   }
# }

# resource "aws_identitystore_user" "user_b" {
#   identity_store_id = local.identity_store_id
#   display_name      = "Hanako Suzuki"
#   user_name         = "hanako.suzuki@example.com"

#   name {
#     given_name  = "Hanako"
#     family_name = "Suzuki"
#   }

#   emails {
#     value   = "hanako.suzuki@example.com"
#     primary = true
#   }
# }

# # ユーザーをグループに追加
# resource "aws_identitystore_group_membership" "admin_membership" {
#   identity_store_id = local.identity_store_id
#   group_id          = aws_identitystore_group.administrators.group_id
#   member_id         = aws_identitystore_user.user_a.user_id
# }

# resource "aws_identitystore_group_membership" "developer_membership" {
#   identity_store_id = local.identity_store_id
#   group_id          = aws_identitystore_group.developers.group_id
#   member_id         = aws_identitystore_user.user_b.user_id
# }


# #-------------------------------------------------
# # アカウント割り当て (Account Assignments)
# #-------------------------------------------------

# # 管理者グループをAWSアカウントに割り当て
# resource "aws_ssoadmin_account_assignment" "admin_assignment" {
#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.administrator.arn

#   principal_id   = aws_identitystore_group.administrators.group_id
#   principal_type = "GROUP"

#   target_id   = var.aws_account_id
#   target_type = "AWS_ACCOUNT"
# }

# # 開発者グループをAWSアカウントに割り当て
# resource "aws_ssoadmin_account_assignment" "developer_assignment" {
#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.developer.arn

#   principal_id   = aws_identitystore_group.developers.group_id
#   principal_type = "GROUP"

#   target_id   = var.aws_account_id
#   target_type = "AWS_ACCOUNT"
# }