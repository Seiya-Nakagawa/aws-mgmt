locals {
    member_accounts = jsondecode(data.aws_ssm_parameter.accounts.value)

  # OU名とOUリソースのIDをマッピングするヘルパー
  ou_id_map = {
    dev = aws_organizations_organizational_unit.ou_dev.id
    prd = aws_organizations_organizational_unit.ou_prd.id
  }
  # SSOインスタンスのARNとIdentity Store IDを抽出
  sso_instance_arn  = one(data.aws_ssoadmin_instances.sso_instances.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)

  # SSMパラメータからユーザー情報を読み込み、JSONをパース
  sso_users = jsondecode(data.aws_ssm_parameter.sso_users.value)

  # 全てのユーザーをフラットなマップに変換（キーはemail）
  all_users = {
    for user in local.sso_users : user.email => {
      familyName = user.familyName
      givenName  = user.givenName
    }
  }

  # グループとグループIDのマップを作成
  sso_groups = {
    "Administrators"   = aws_identitystore_group.administrators.group_id
    "ProductionUsers"  = aws_identitystore_group.production.group_id
    "DevelopmentUsers" = aws_identitystore_group.development.group_id
  }

  # グループメンバーシップをフラットなリストに変換
  group_memberships = flatten([
    for user_details in local.sso_users : [
      for group_name in user_details.groups : {
        user_email = user_details.email
        group_id   = local.sso_groups[group_name]
      }
    ]
  ])
}