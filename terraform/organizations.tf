# ----------------------------------------------------------------
# Service: AWS Organizations
# ----------------------------------------------------------------

# AWS Organizationsの設定を管理します。
resource "aws_organizations_organization" "admin_org" {
  # この設定により、SCPやタグポリシーなど全ての機能が利用可能になります
  feature_set = "ALL"

  # 有効化したいポリシータイプを指定します
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}


# 本番用OU
resource "aws_organizations_organizational_unit" "admin_ou_prd" {
  name      = "${var.project_name}-${var.env}-ou-prd"
  parent_id = aws_organizations_organization.admin_org.roots[0].id
}

# 開発用OU
resource "aws_organizations_organizational_unit" "admin_ou_dev" {
  name      = "${var.project_name}-${var.env}-ou-dev"
  parent_id = aws_organizations_organization.admin_org.roots[0].id
}

# Todo:システム構築完了後に有効化
# メンバーアカウントの作成
# resource "aws_organizations_account" "admin_ou_dev" {
#   for_each = var.new_accounts
#   name      = each.value.name
#   email     = each.value.email
#   parent_id = local.ou_ids[each.value.ou_name]
#   role_name = "OrganizationAccountAccessRole"
# }

# リージョン制約ポリシー
resource "aws_organizations_policy" "admin_orgpolicy_region_restriction" {
  name    = "${var.project_name}-${var.env}-orgpolicy-block-region"
  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "DenyRegionalServicesOutsideAllowedRegion",
        Effect   = "Deny",
        NotAction = [
          # ローバルサービスについては、リージョン制限対象から除外する。
          "iam:*",
          "organizations:*",
          "route53:*",
          "route53domains:*",
          "cloudfront:*",
          "sts:*",
          "a4b:*",
          "acm:*",
          "aws-marketplace-management:*",
          "aws-portal:*",
          "budgets:*",
          "ce:*",
          "directconnect:*",
          "ec2:DescribeRegions", # マネジメントコンソールでのリージョン一覧表示に必要
          "globalaccelerator:*",
          "health:*",
          "importexport:*",
          "shield:*",
          "support:*",
          "trustedadvisor:*",
          "waf:*",
          "waf-regional:*",
          "wafv2:*"
        ],
        Resource = "*",
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "ap-northeast-1"
            ]
          }
        }
      }
    ]
  })
}

# ルートユーザーの操作をブロックするポリシー
resource "aws_organizations_policy" "admin_orgpolicy_block_root" {
  name = "${var.project_name}-${var.env}-orgpolicy-deny-root"
  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Deny",
        Action   = "*",
        Resource = "*",
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# ガバナンス保護ポリシー
resource "aws_organizations_policy" "admin_orgpolicy_governance" {
  name = "${var.project_name}-${var.env}-orgpolicy-protect-governance"
  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Deny",
        Action = [
          "organizations:LeaveOrganization",
          "organizations:DeleteOrganization",
          "organizations:RemoveAccountFromOrganization"
        ],
        Resource = "*",
        Condition = {
          # 例: 特定の管理ロール以外からの操作を拒否
          # このように他のリソースのARNを参照できます
          ArnNotEquals = {
            # "aws:PrincipalArn" = aws_iam_role.organization_admin.arn
          }
        }
      }
    ]
  })
}

# ポリシーをルートにアタッチ
resource "aws_organizations_policy_attachment" "admin_orgpolicy_attach_root" {
  for_each = {
    region_restriction = aws_organizations_policy.admin_orgpolicy_region_restriction.id
    block_root_user    = aws_organizations_policy.admin_orgpolicy_block_root.id
    protect_governance = aws_organizations_policy.admin_orgpolicy_governance.id
  }
  policy_id = each.value
  target_id = aws_organizations_organization.admin_org.roots[0].id
}