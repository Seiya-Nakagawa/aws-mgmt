locals {
  member_accounts = jsondecode(file("${path.module}/json/member_accounts.json"))

  # OU名とOUリソースのIDをマッピングするヘルパー
  ou_id_map = {
    dev = aws_organizations_organizational_unit.ou_dev.id
    prd = aws_organizations_organizational_unit.ou_prd.id
  }
  # SSOインスタンスのARNとIdentity Store IDを抽出
  sso_instance_arn  = one(data.aws_ssoadmin_instances.sso_instances.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)

  # member_accounts.json から管理者ユーザーのリストを平坦化
  administrator_emails = toset(flatten([
    for account in local.member_accounts : account.administrators
  ]))

  # 開発者の割り当て情報をフラットなリストとして作成
  developer_assignments_list = flatten([
    for account in local.member_accounts :
    [
      for email in account.developers : {
        account_name       = account.name
        account_root_email = account.email
        developer_email    = email
        ou_name            = account.ou_name
      }
    ]
  ])

  # 上記のリストを元に、Terraform 0.13以前と互換性のある方法でマップを生成
  sso_assignments = {
    for dev in local.developer_assignments_list : "${dev.account_name}-dev-${dev.developer_email}" => {
      account_id         = aws_organizations_account.member_accounts[dev.account_root_email].id
      user_email         = dev.developer_email
      permission_set_arn = dev.ou_name == "prd" ? aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn : aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn
    }
  }
}