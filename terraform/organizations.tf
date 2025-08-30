# AWS Organizationsの設定
resource "aws_organizations_organization" "org" {
  # この設定により、SCPやタグポリシーなど全ての機能が利用可能になります
  feature_set = "ALL"

  # 有効化したいポリシータイプを指定します
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]

  aws_service_access_principals = [
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "access-analyzer.amazonaws.com",
  ]
}

# 本番用OU
resource "aws_organizations_organizational_unit" "ou_prd" {
  name      = "${var.system_name}-${var.env}-ou-prd"
  parent_id = aws_organizations_organization.org.roots[0].id

  tags = {
    Name        = "${var.system_name}-${var.env}-ou-prd",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}

# 開発用OU
resource "aws_organizations_organizational_unit" "ou_dev" {
  name      = "${var.system_name}-${var.env}-ou-dev"
  parent_id = aws_organizations_organization.org.roots[0].id

  tags = {
    Name        = "${var.system_name}-${var.env}-ou-dev",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}

# メンバーアカウントの作成
resource "aws_organizations_account" "member_accounts" {
  for_each = { for acc in local.member_accounts : acc.email => acc }
  name      = each.value.name
  email     = each.value.email
  parent_id = local.ou_id_map[each.value.ou_name]
  role_name = "OrganizationAccountAccessRole"
}

# リージョン制約ポリシー
resource "aws_organizations_policy" "org_policy_region_restriction" {
  name    = "${var.system_name}-${var.env}-orgpolicy-block-region"
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

  tags = {
    Name        = "${var.system_name}-${var.env}-orgpolicy-block-region"
    SystemName  = var.system_name,
    Env         = var.env,
  }
  depends_on = [aws_organizations_organization.org] 
}

# ルートユーザーの操作をブロックするポリシー
resource "aws_organizations_policy" "org_policy_block_root" {
  name = "${var.system_name}-${var.env}-orgpolicy-deny-root"
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

  tags = {
    Name        = "${var.system_name}-${var.env}-orgpolicy-deny-root",
    SystemName  = var.system_name,
    Env         = var.env,
  }
  depends_on = [aws_organizations_organization.org] 
}

# ガバナンス保護ポリシー
resource "aws_organizations_policy" "org_policy_governance" {
  name = "${var.system_name}-${var.env}-orgpolicy-protect-governance"
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
          # 管理アカウント以外は拒否
          StringNotEquals = {
            "aws:PrincipalAccount" = [data.aws_caller_identity.caller_identity.account_id]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.system_name}-${var.env}-orgpolicy-protect-governance",
    SystemName  = var.system_name,
    Env         = var.env,
  }
  depends_on = [aws_organizations_organization.org] 
}

# ポリシーをルートにアタッチ
resource "aws_organizations_policy_attachment" "org_policy_attach_root" {
  for_each = {
    region_restriction = aws_organizations_policy.org_policy_region_restriction.id
    block_root_user    = aws_organizations_policy.org_policy_block_root.id
    protect_governance = aws_organizations_policy.org_policy_governance.id
    # tag                = aws_organizations_policy.org_policy_tag.id
  }
  policy_id = each.value
  target_id = aws_organizations_organization.org.roots[0].id
}