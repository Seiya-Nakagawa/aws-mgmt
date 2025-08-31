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

# 本番開発者用許可セット
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

# 開発者用許可セット
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

# 管理者グループの作成
resource "aws_identitystore_group" "administrators" {
  display_name      = "Administrators"
  description       = "Group for administrators"
  identity_store_id = local.identity_store_id
}



# 管理者ユーザーの作成
resource "aws_identitystore_user" "administrators" {
  for_each = local.administrator_emails

  identity_store_id = local.identity_store_id
  user_name         = each.key # Assuming each.key is the desired username (e.g., email)
  display_name      = each.key # Using username as display name for simplicity
}

# 管理者グループへのメンバーシップを作成
resource "aws_identitystore_group_membership" "administrators" {
  for_each = aws_identitystore_user.administrators

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.administrators.group_id
  member_id         = each.value.id
}

# 管理者グループにすべてのメンバーアカウントへの権限を割り当て
resource "aws_ssoadmin_account_assignment" "administrators_group_assignment" {
  for_each = aws_organizations_account.member_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator.arn

  principal_id   = aws_identitystore_group.administrators.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}

# member_accounts.json に定義された全ユーザーの情報を参照
data "aws_identitystore_user" "all_assigned_users" {
  for_each = toset([
    for assignment in values(local.sso_assignments) : assignment.user_email
  ])
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}

# local.sso_assignments マップに基づき、全アカウント割り当てを動的に生成
resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = local.sso_assignments

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = data.aws_identitystore_user.all_assigned_users[each.value.user_email].user_id
  principal_type = "USER"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
