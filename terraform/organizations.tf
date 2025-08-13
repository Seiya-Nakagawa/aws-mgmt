# ----------------------------------------------------------------
# Service: AWS Organizations
# ----------------------------------------------------------------

resource "aws_organizations_organizational_unit" "admin_ou_prd" {
  name      = "${var.project_name}-${var.env}-ou-prd"
  parent_id = data.aws_organizations_organization.admin_org.roots[0].id
}

resource "aws_organizations_organizational_unit" "admin_ou_dev" {
  name      = "${var.project_name}-${var.env}-ou-dev"
  parent_id = data.aws_organizations_organization.admin_org.roots[0].id
}

# resource "aws_organizations_account" "admin_ou_dev" {
#   for_each = var.new_accounts
#   name      = each.value.name
#   email     = each.value.email
#   parent_id = local.ou_ids[each.value.ou_name]
#   role_name = "OrganizationAccountAccessRole"
# }

resource "aws_organizations_policy" "admin_orgpolicy_region_restriction" {
  name    = "${var.project_name}-${var.env}-orgpolicy-block-region"
  content = file("${path.module}/policies/region_restriction.json")
}

resource "aws_organizations_policy" "admin_orgpolicy_block_root" {
  name    = "${var.project_name}-${var.env}-orgpolicy-deny-root"
  content = file("${path.module}/policies/block_root_user.json")
}

resource "aws_organizations_policy" "admin_orgpolicy_governance" {
  name    = "${var.project_name}-${var.env}-orgpolicy-protect-governance"
  content = file("${path.module}/policies/governance.json")
}

resource "aws_organizations_policy_attachment" "attach_scps_to_root" {
  for_each = {
    region_restriction = aws_organizations_policy.admin_orgpolicy_region_restriction.id
    block_root_user    = aws_organizations_policy.admin_orgpolicy_block_root.id
    protect_governance = aws_organizations_policy.admin_orgpolicy_governance.id
  }
  policy_id = each.value
  target_id = data.aws_organizations_organization.admin_org.roots[0].id
}
