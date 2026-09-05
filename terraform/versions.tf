# versions.tf
## AWS Profile: default
## AWS Account ID: 572354497317

# Terraformの実行環境に関する設定
terraform {
  required_version = ">= 1.12.2"

  # Terraform Cloudをバックエンドとして設定
  cloud {
    organization = "aibdlnew1-organization"

    # このコードがどのワークスペース群に属するかを示すタグを設定
    workspaces {
      name = "aws-admin-cmn"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}

# プライマリリージョン (東京)
provider "aws" {
  region = "ap-northeast-1"
}

# グローバルサービス用プロバイダ (バージニア北部)
# IAM Identity Center, Budgets等の操作に利用
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# 本番アカウント操作用プロバイダ
# 本番アカウントが組織のメンバーである間、OrganizationAccountAccessRoleへ
# assume_roleすることで、管理アカウントの認証情報のまま本番アカウント直下に
# リソースを構築する（Issue #14: 組織離脱後はワークスペースの認証情報自体を
# 本番アカウント向けに切り替える想定）
provider "aws" {
  alias  = "production"
  region = "ap-northeast-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.production_account_id}:role/OrganizationAccountAccessRole"
  }
}