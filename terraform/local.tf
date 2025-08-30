locals {
  member_accounts = jsondecode(file("${path.module}/member_accounts.json"))
  

  # OU名とOUリソースのIDをマッピングするヘルパー
  ou_id_map = {
    dev = aws_organizations_organizational_unit.ou_dev.id
    prd = aws_organizations_organizational_unit.ou_prd.id
  }
  # SSOインスタンスのARNとIdentity Store IDを抽出
  sso_instance_arn  = one(data.aws_ssoadmin_instances.sso_instances.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)

  # SSMから取得した値を、ユーザーごとに使いやすいマップ形式に再構成
  sso_users_data = {
    for user_id in var.sso_user_ids : user_id => {
      given_name  = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/given_name"].value
      family_name = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/family_name"].value
      email       = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/email"].value
      group       = data.aws_ssm_parameter.user_params["/sso/users/${user_id}/group"].value
    }
  }
}