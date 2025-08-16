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

# 本番OU (Production) に所属する全メンバーアカウントの情報を取得
data "aws_organizations_organizational_unit_child_accounts" "production" {
  parent_id = aws_organizations_organizational_unit.ou_prd.id
}

# 開発OU (Development) に所属する全メンバーアカウントの情報を取得
data "aws_organizations_organizational_unit_child_accounts" "development" {
  parent_id = aws_organizations_organizational_unit.ou_dev.id
}

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

# 組織管理用許可セット
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
resource "aws_ssoadmin_permission_set" "ssopermsets_prd_developer" {
  name             = "${var.system_name}-${var.env}-ssopermsets-prd-developer"
  description      = "Permission set for developers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_prd_developer_poweruser" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_prd_developer.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_prd_developer_iamread" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_prd_developer.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

# 開発者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_dev_developer" {
  name             = "${var.system_name}-${var.env}-ssopermsets-dev-developer"
  description      = "Permission set for developers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_developer_policy" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_dev_developer.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

#-------------------------------------------------
# グループとユーザー (Groups and Users)
#-------------------------------------------------

# 組織管理グループ
resource "aws_identitystore_group" "identity_group_administrators" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.system_name}-${var.env}-group-administrators"
  description       = "Administrators group"
  depends_on = [
    # Organizationsが作成された後に実行されることを保証
    aws_organizations_organization.org
  ]
}

# 本番開発者グループ
resource "aws_identitystore_group" "identity_group_prd_developers" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.system_name}-${var.env}-group-prd-developers"
  description       = "Developers group"
  depends_on = [
    aws_organizations_organization.org
  ]
}

# 開発者グループ
resource "aws_identitystore_group" "identity_group_dev_developers" {
  identity_store_id = local.identity_store_id
  display_name      = "${var.system_name}-${var.env}-group-dev-developers"
  description       = "Developers group"
  depends_on = [
    aws_organizations_organization.org
  ]
}

# ユーザーの作成
resource "aws_identitystore_user" "identity_user" {
  for_each          = local.sso_users_data
  identity_store_id = local.identity_store_id

  user_name    = each.value.email
  display_name = "${each.value.given_name} ${each.value.family_name}"

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

# 組織管理グループのメンバーシップを作成
resource "aws_identitystore_group_membership" "admin_members" {
  for_each = nonsensitive({
    for user_id, user_data in local.sso_users_data : user_id => user_data
    if user_data.group == "administrators"
  })

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.identity_group_administrators.group_id
  member_id         = aws_identitystore_user.identity_user[each.key].user_id
}

# 本番開発者グループのメンバーシップを作成
resource "aws_identitystore_group_membership" "prd_developer_members" {
  for_each = nonsensitive({
    for user_id, user_data in local.sso_users_data : user_id => user_data
    if user_data.group == "prd_developers"
  })

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.identity_group_prd_developers.group_id
  member_id         = aws_identitystore_user.identity_user[each.key].user_id
}

# 開発者グループのメンバーシップを作成
resource "aws_identitystore_group_membership" "dev_developer_members" {
  for_each = nonsensitive({
    for user_id, user_data in local.sso_users_data : user_id => user_data
    if user_data.group == "dev_developers"
  })

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.identity_group_dev_developers.group_id
  member_id         = aws_identitystore_user.identity_user[each.key].user_id
}

#-------------------------------------------------
# アカウント割り当て (Account Assignments)
#-------------------------------------------------

# 管理者グループをAWSアカウントに割り当て
resource "aws_ssoadmin_account_assignment" "admin_account" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn

  principal_id   = aws_identitystore_group.identity_group_administrators.group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.caller_identity.account_id
  target_type = "AWS_ACCOUNT"
}


# 本番環境の開発者グループを本番の全メンバーアカウントに割り当て
resource "aws_ssoadmin_account_assignment" "developer_account_prd" {
  # (管理者グループ) と (本番OUの全アカウントIDリスト) の組み合わせを生成
  for_each = {
    for account_id in [for acc in data.aws_organizations_organizational_unit_child_accounts.ou_prd.accounts : acc.id] :
    "${aws_identitystore_group.identity_group_prd_developers.group_id}-${account_id}" => {
      group_id    = aws_identitystore_group.identity_group_prd_developers.group_id
      account_id  = account_id
    }
  }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn
  
  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}


# 開発環境の開発者グループを開発の全メンバーアカウントに割り当て
resource "aws_ssoadmin_account_assignment" "developer_account_dev" {
  # (管理者グループ) と (本番OUの全アカウントIDリスト) の組み合わせを生成
  for_each = {
    for account_id in [for acc in data.aws_organizations_organizational_unit_child_accounts.ou_dev.accounts : acc.id] :
    "${aws_identitystore_group.identity_group_dev_developers.group_id}-${account_id}" => {
      group_id    = aws_identitystore_group.identity_group_dev_developers.group_id
      account_id  = account_id
    }
  }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn
  
  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
