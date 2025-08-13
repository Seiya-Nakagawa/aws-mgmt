# ----------------------------------------------------------------
# 共通定義ファイル (データソース, ローカル変数)
# ----------------------------------------------------------------

# --- データソース: 既存のOrganization/SSOインスタンス情報を取得 ---
data "aws_organizations_organization" "admin_org" {}

data "aws_ssoadmin_instances" "admin_sso" {
  provider = aws.us-east-1
}

# --- ローカル変数: 複数のリソースで参照する値を定義 ---
locals {
  sso_instance_arn = data.aws_ssoadmin_instances.sso.arns[0]

  # 作成するOUのIDをマップとして管理し、アカウント作成時に参照する
  ou_ids = {
    # このマップは service-organizations.tf で定義されたOUを参照します
    "Workloads-Dev" = aws_organizations_organizational_unit.workloads_dev.id
    "Workloads-Prd" = aws_organizations_organizational_unit.workloads_prd.id
  }
}