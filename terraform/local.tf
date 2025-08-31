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

  # member_accounts.json のデータから、アカウント割り当てのマップを動的に生成
  # このマップを sso.tf の for_each で利用する
  sso_assignments = {
    for account in local.member_accounts :
    for email in account.developers :
    # ループのキーは "アカウント名-dev-Email" の形式で一意にする
    "${account.name}-dev-${email}" => {
      account_id         = aws_organizations_account.member_accounts[account.email].id
      user_email         = email
      # アカウントのOU名に応じて、本番用/開発用の開発者権限を割り当てる
      permission_set_arn = account.ou_name == "prd" ? aws_ssoadmin_permission_set.ssopermsets_prd_developer.arn : aws_ssoadmin_permission_set.ssopermsets_dev_developer.arn
    }
  }
}