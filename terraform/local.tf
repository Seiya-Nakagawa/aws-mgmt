locals {
  # --- Account Data Processing ---
  # 各アカウントの詳細情報をパースしてマップに変換
  # 例: "portfolio-prd" => { name = "portfolio-prd", email = "...", ou_name = "prd" }
  member_accounts_map = {
    for id, param in data.aws_ssm_parameter.accounts : id => jsondecode(param.value)
  }

  # --- User Data Processing ---
  # 各ユーザーの詳細情報をパースしてマップに変換
  # 例: "admin_user" => { email = "...", familyName = "...", ... }
  sso_users_map = {
    for id, param in data.aws_ssm_parameter.users : id => jsondecode(param.value)
  }

  # 全ユーザーのemailをキーにしたマップを作成 (aws_identitystore_userリソース用)
  # 例: "admin@example.com" => { familyName = "...", givenName = "..." }
  all_users = {
    for user_details in values(local.sso_users_map) : user_details.email => {
      familyName = user_details.familyName
      givenName  = user_details.givenName
    }
  }

  # グループメンバーシップをフラットなリストに変換 (aws_identitystore_group_membershipリソース用)
  group_memberships = flatten([
    for user_details in values(local.sso_users_map) : [
      for group_name in user_details.groups : {
        user_email = user_details.email
        group_id   = local.sso_groups[group_name] # sso_groupsは後で定義
      }
    ]
  ])

  # --- Helper Maps ---
  # OU名とOUリソースのIDをマッピング
  ou_id_map = {
    dev = aws_organizations_organizational_unit.ou_dev.id
    prd = aws_organizations_organizational_unit.ou_prd.id
  }

  # グループ名とグループIDのマップ
  sso_groups = {
    "Administrators"   = aws_identitystore_group.administrators.group_id
    "ProductionUsers"  = aws_identitystore_group.production.group_id
    "DevelopmentUsers" = aws_identitystore_group.development.group_id
  }

  # --- SSO Instance Info ---
  sso_instance_arn  = one(data.aws_ssoadmin_instances.sso_instances.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)
}