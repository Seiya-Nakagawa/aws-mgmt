locals {
  # ==============================================================================
  # ▼▼▼ アカウントの定義はすべてここで行います ▼▼▼
  #
  # ここで定義した静的な情報をもとに、アカウント作成とSSO割り当てを行います。
  # キー ("dev_main_app", "prd_payment"など) はTerraform内で使う一意な識別子です。
  # ==============================================================================
  accounts = {
    "dev_main_app" = {
      name  = "${var.system_name}-${var.env}-dev-main-app"
      email = "your-email+dev-main-app@example.com" # 実際の一意なメールアドレスに変更してください
      ou    = "dev" # "dev" または "prd" を指定
    },
    "dev_analytics" = {
      name  = "${var.system_name}-${var.env}-dev-analytics"
      email = "your-email+dev-analytics@example.com" # 実際の一意なメールアドレスに変更してください
      ou    = "dev"
    },
    "prd_main_app" = {
      name  = "${var.system_name}-${var.env}-prd-main-app"
      email = "your-email+prd-main-app@example.com" # 実際の一意なメールアドレスに変更してください
      ou    = "prd"
    }
  }

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