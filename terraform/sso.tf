# 組織管理用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_administrator" {
  name             = "${var.system_name}-${var.env}-ps-admin"
  description      = "Permission set for administrators"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H" # 4時間
  tags = {
    Name        = "${var.system_name}-${var.env}-ps-admin",
    SystemName  = var.system_name,
    Env         = var.env,
    CreatedDate = terraform_data.creation_time.input
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_administrator_policy" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_administrator.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 開発者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_prd_developer" {
  name             = "${var.system_name}-${var.env}-ps-prd-developer"
  description      = "Permission set for developers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
  tags = {
    Name        = "${var.system_name}-${var.env}-ps-prd-developer",
    SystemName  = var.system_name,
    Env         = var.env,
    CreatedDate = terraform_data.creation_time.input
  }
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
  name             = "${var.system_name}-${var.env}-ps-dev-developer"
  description      = "Permission set for developers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
  tags = {
    Name        = "${var.system_name}-${var.env}-ps-dev-developer",
    SystemName  = var.system_name,
    Env         = var.env,
    CreatedDate = terraform_data.creation_time.input
  }
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
# resource "aws_ssoadmin_account_assignment" "developer_account_prd" {
#   # (管理者グループ) と (本番OUの全アカウントIDリスト) の組み合わせを生成
#   for_each = {
#     for account_id in [for acc in data.aws_organizations_organizational_unit_child_accounts.prd_accounts_list.accounts : acc.id] :
#     "${aws_identitystore_group.identity_group_prd_developers.group_id}-${account_id}" => {
#       group_id    = aws_identitystore_group.identity_group_prd_developers.group_id
#       account_id  = account_id
#     }
#   }

#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn
  
#   principal_id   = each.value.group_id
#   principal_type = "GROUP"

#   target_id   = each.value.account_id
#   target_type = "AWS_ACCOUNT"
# }


# # 開発環境の開発者グループを開発の全メンバーアカウントに割り当て
# resource "aws_ssoadmin_account_assignment" "developer_account_dev" {
#   # (管理者グループ) と (本番OUの全アカウントIDリスト) の組み合わせを生成
#   for_each = {
#     for account_id in [for acc in data.aws_organizations_organizational_unit_child_accounts.dev_accounts_list.accounts : acc.id] :
#     "${aws_identitystore_group.identity_group_dev_developers.group_id}-${account_id}" => {
#       group_id    = aws_identitystore_group.identity_group_dev_developers.group_id
#       account_id  = account_id
#     }
#   }

#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn
  
#   principal_id   = each.value.group_id
#   principal_type = "GROUP"

#   target_id   = each.value.account_id
#   target_type = "AWS_ACCOUNT"
# }
