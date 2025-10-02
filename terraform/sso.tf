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
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_administrator_policy" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_administrator.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 本番環境開発者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_prd_developer" {
  name             = "${var.system_name}-${var.env}-ps-prd-developer"
  description      = "Permission set for developers in Production"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
  tags = {
    Name        = "${var.system_name}-${var.env}-ps-prd-developer",
    SystemName  = var.system_name,
    Env         = var.env,
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

# 開発環境開発者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_dev_developer" {
  name             = "${var.system_name}-${var.env}-ps-dev-developer"
  description      = "Permission set for developers in Development"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8時間
  tags = {
    Name        = "${var.system_name}-${var.env}-ps-dev-developer",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_developer_policy" {
  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_dev_developer.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

#-------------------------------------------------
# アカウント割り当て (Account Assignments)
#-------------------------------------------------

# メンバー用管理者グループの作成
resource "aws_identitystore_group" "administrators" {
  display_name      = "Administrators"
  description       = "Group for administrators"
  identity_store_id = local.identity_store_id
}

# 本番環境ユーザーグループの作成
resource "aws_identitystore_group" "production" {
  display_name      = "ProductionUsers"
  description       = "Group for production users"
  identity_store_id = local.identity_store_id
}

# 開発環境ユーザーグループの作成
resource "aws_identitystore_group" "development" {
  display_name      = "DevelopmentUsers"
  description       = "Group for development users"
  identity_store_id = local.identity_store_id
}

# パラメータストアの情報を元に、Identity Centerのユーザーを一括で作成
resource "aws_identitystore_user" "users" {
  for_each = nonsensitive(local.users_by_hash)

  identity_store_id = local.identity_store_id
  user_name         = each.value.email
  display_name      = "${each.value.givenName} ${each.value.familyName}"

  name {
    family_name = each.value.familyName
    given_name  = each.value.givenName
  }

  emails {
    value = each.value.email
    type  = "work"
  }
}

# パラメータストアの情報を元に、グループメンバーシップを一括で作成
resource "aws_identitystore_group_membership" "memberships" {
  for_each = nonsensitive({ for i, m in local.group_memberships : "${m.user_hash}-${m.group_id}" => m })

  identity_store_id = local.identity_store_id
  group_id          = each.value.group_id
  member_id         = aws_identitystore_user.users[each.value.user_hash].user_id
}

#-------------------------------------------------
# グループへの権限割り当て (Group Account Assignments)
#-------------------------------------------------

# 管理者グループへの権限割り当て (Administrator, Production, Development)
resource "aws_ssoadmin_account_assignment" "admin_group_admin_permissions" {
  for_each = aws_organizations_account.member_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn

  principal_id   = aws_identitystore_group.administrators.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}



# 本番グループへの権限割り当て (Production)
resource "aws_ssoadmin_account_assignment" "production_group_permissions" {
  for_each = aws_organizations_account.member_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn

  principal_id   = aws_identitystore_group.production.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}

# 開発グループへの権限割り当て (Development)
resource "aws_ssoadmin_account_assignment" "development_group_permissions" {
  for_each = aws_organizations_account.member_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn

  principal_id   = aws_identitystore_group.development.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}

# 管理アカウントへの管理者グループの権限割り当て
resource "aws_ssoadmin_account_assignment" "admin_group_management_account_permissions" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn

  principal_id   = aws_identitystore_group.administrators.group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.caller_identity.account_id
  target_type = "AWS_ACCOUNT"
}