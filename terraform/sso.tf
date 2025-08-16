#-------------------------------------------------
# データソース (Data Sources)
#-------------------------------------------------

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

#-------------------------------------------------
# ローカル変数 (Locals)
#-------------------------------------------------
locals {
  # SSOインスタンスのARNとIdentity Store IDを抽出
  sso_instance_arn  = one(data.aws_ssoadmin_instances.sso_instances.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)

  # SSMから取得した値を、ユーザーごとに使いやすいマップ形式に再構成
  sso_users_data = {
    for user_id in var.sso_user_ids : user_id => {
      given_name  = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/given_name"].value
      family_name = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/family_name"].value
      email       = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/email"].value
      group       = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/group"].value
    }
  }
}

#-------------------------------------------------
# 許可セット (Permission Sets)
#-------------------------------------------------

# 管理者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_administrator" {
  name             = "${var.system_name}-${var.env}-ssopermsets-admin"
  description      = "Permission set for administrators"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H" # 4時間
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_administrator_policy" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_administrator.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 開発者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_developer" {
  name             = "${var.system_name}-${var.env}-ssopermsets-developer"
  description      = "Permission set for developers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_developer_policy" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_developer.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

#-------------------------------------------------
# グループとユーザー (Groups and Users)
#-------------------------------------------------

# 管理者グループ
resource "aws_identitystore_group" "identity_group_administrators" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.system_name}-${var.env}-group-administrators"
  description       = "Administrators group"
  depends_on = [
    # Organizationsが作成された後に実行されることを保証
    aws_organizations_organization.org
  ]
}

# 開発者グループ
resource "aws_identitystore_group" "identity_group_developers" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.system_name}-${var.env}-group-developers"
  description       = "Developers group"
  depends_on = [
    aws_organizations_organization.org
  ]
}

# ユーザーの作成
resource "aws_identitystore_user" "identity_user_admin" {
  for_each          = local.sso_users_data
  identity_store_id = local.identity_store_id

  user_name    = each.value.email
  display_name = "${each.value.given_name} ${each.value.family_name}" # ドット(.)をスペースに変更

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

#-------------------------------------------------
# グループへの所属 (Group Memberships)
#-------------------------------------------------

# 管理者グループのメンバーシップを作成
resource "aws_identitystore_group_membership" "admin_members" {
  for_each = nonsensitive({
    for user_id, user_data in local.sso_users_data : user_id => user_data
    if user_data.group == "administrators"
  })

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.identity_group_administrators.group_id
  member_id         = aws_identitystore_user.identity_user_admin[each.key].user_id
}

# 開発者グループのメンバーシップを作成
resource "aws_identitystore_group_membership" "developer_members" {
  for_each = nonsensitive({
    for user_id, user_data in local.sso_users_data : user_id => user_data
    if user_data.group == "developers"
  })

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.identity_group_developers.group_id
  member_id         = aws_identitystore_user.identity_user_admin[each.key].user_id
}

#-------------------------------------------------
# アカウント割り当て (Account Assignments)
#-------------------------------------------------

# 管理者グループをAWSアカウントに割り当て
resource "aws_ssoadmin_account_assignment" "admin_management_account" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn

  principal_id   = aws_identitystore_group.identity_group_administrators.group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.caller_identity.account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_on_member_account" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_developer.arn

  principal_id   = aws_identitystore_group.identity_group_administrators.group_id
  principal_type = "GROUP"

  target_id   = var.member_account_id
  target_type = "AWS_ACCOUNT"
}

# 開発者グループをAWSアカウントに割り当て
# resource "aws_ssoadmin_account_assignment" "developer_assignment" {
#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_developer.arn

#   principal_id   = aws_identitystore_group.identity_group_developers.group_id
#   principal_type = "GROUP"

#   target_id   = data.aws_caller_identity.caller_identity.account_id
#   target_type = "AWS_ACCOUNT"
# }