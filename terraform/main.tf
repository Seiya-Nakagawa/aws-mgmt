# ----------------------------------------------------------------
# 共通定義ファイル (データソース, ローカル変数)
# ----------------------------------------------------------------

# --- データソース: 既存のOrganization/SSOインスタンス情報を取得 ---
data "aws_organizations_organization" "admin_org" {}

data "aws_ssoadmin_instances" "admin_sso" {}

# --- ローカル変数: 複数のリソースで参照する値を定義 ---
locals {
  sso_instance_arn = data.aws_ssoadmin_instances.admin_sso.arns[0]

  # 作成するOUのIDをマップとして管理し、アカウント作成時に参照する
  ou_ids = {
    "Workloads-Prd" = aws_organizations_organizational_unit.admin_ou_prd.id
    "Workloads-Dev" = aws_organizations_organizational_unit.admin_ou_dev.id
  }
}