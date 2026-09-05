# 本番アカウント直下のIAM Identity Center（アカウントインスタンス）関連リソース
#
# アカウントインスタンス自体の有効化はTerraformでは行えない（対応するリソースが
# 存在しない）ため、事前に本番アカウント上で手動で有効化しておく必要がある
# （docs/03.構築/02_本番アカウント直下へのIAM Identity Center構築.md参照）。
# 本ファイルでは、有効化済みのアカウントインスタンスに対して管理者用の許可セット・
# ユーザー・アカウント割り当てを作成する。
#
# インスタンスARN・Identity Store IDは`aws_ssoadmin_instances`データソースで動的に
# 取得せず、変数（`production_sso_instance_arn`, `production_identity_store_id`）で
# 明示的に指定する。本番アカウントがまだAWS Organizationsのメンバーである間、当該
# データソースは新しく作成したアカウントインスタンスと既存の組織インスタンスの
# 両方を返してしまい一意に定まらないため。
#
# 本番アカウントがまだAWS Organizationsのメンバーである間は、production.tfと同様に
# OrganizationAccountAccessRoleへのassume_role（provider = aws.production）で操作する。

# 管理者用許可セット
resource "aws_ssoadmin_permission_set" "ssopermsets_administrator_production" {
  provider = aws.production

  name             = "${var.system_name}-${var.env}-ps-admin-prd"
  description      = "Permission set for the production account administrator"
  instance_arn     = var.production_sso_instance_arn
  session_duration = "PT4H" # 4時間
  tags = {
    Name       = "${var.system_name}-${var.env}-ps-admin-prd",
    SystemName = var.system_name,
    Env        = var.env,
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "ssopermsets_administrator_production_policy" {
  provider = aws.production

  instance_arn       = aws_ssoadmin_permission_set.ssopermsets_administrator_production.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator_production.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 管理者ユーザー
resource "aws_identitystore_user" "admin_production" {
  provider = aws.production

  identity_store_id = var.production_identity_store_id
  user_name         = var.admin_email
  display_name      = "${var.admin_given_name} ${var.admin_family_name}"

  name {
    family_name = var.admin_family_name
    given_name  = var.admin_given_name
  }

  emails {
    value = var.admin_email
    type  = "work"
  }
}

# 管理者ユーザーへの許可セット割り当て（本番アカウント自身が対象）
resource "aws_ssoadmin_account_assignment" "admin_account_assignment_production" {
  provider = aws.production

  instance_arn       = var.production_sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ssopermsets_administrator_production.arn

  principal_id   = aws_identitystore_user.admin_production.user_id
  principal_type = "USER"

  target_id   = var.production_account_id
  target_type = "AWS_ACCOUNT"
}
