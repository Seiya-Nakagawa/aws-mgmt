# versions.tf

# Terraformの実行環境に関する設定
terraform {
  # required_version = ">= 1.12.2"
  required_version = ">= 1.6.0"

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