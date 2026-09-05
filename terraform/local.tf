locals {
  # --- Data Loading ---
  users_data = jsondecode(data.aws_ssm_parameter.users.value)

  # --- Hashed Maps for for_each ---
  # Create a map of users keyed by email hash for sso.tf
  users_by_hash = { for user in local.users_data : sha256(user.email) => user }

  # --- Data for Group Memberships ---
  # Create the flattened list for group memberships, using the email hash as the user identifier
  group_memberships = flatten([
    for hash, user_details in local.users_by_hash : [
      for group_name in user_details.groups : {
        user_hash = hash
        group_id  = local.sso_groups[group_name] # sso_groups is defined below
      }
    ]
  ])

  # --- Helper Maps ---
  sso_groups = {
    "Administrators"  = aws_identitystore_group.administrators.group_id
    "ProductionUsers" = aws_identitystore_group.production.group_id
  }

  # --- SSO Instance Info ---
  sso_instance_arn  = one(data.aws_ssoadmin_instances.sso_instances.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)
}