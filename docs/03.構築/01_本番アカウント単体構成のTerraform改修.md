# 01 構築手順書 - 本番アカウント単体構成のTerraform改修

## 目次

- [1. 概要](#1-概要)
- [2. 前提条件](#2-前提条件)
- [3. 手順](#3-手順)
  - [3.1. Terraformコードの静的検証](#31-terraformコードの静的検証)
  - [3.2. Terraform Cloudでのplan確認](#32-terraform-cloudでのplan確認)
  - [3.3. apply](#33-apply)
  - [3.4. 動作確認](#34-動作確認)

## 1. 概要

Issue #14（AWSアカウントを本番アカウント1つに統合する）の対応の一部として、AWS Organizations・
メンバーアカウントに依存していたTerraformコードを、本番アカウント単体で動作する構成に書き換える。

CloudTrailについては、コスト効率を優先する要件（[要件定義書 1.1](../【AWS組織管理】要件定義書.md#11-はじめに)、
[4. 非機能要件](../【AWS組織管理】要件定義書.md#4-非機能要件)）に基づき、追加費用の発生するTrail・S3への
保管は構築せず、デフォルトで提供されるEvent history（直近90日分の管理イベント）をそのまま利用する。

本手順書は、Terraformコードの改修と適用のみを対象とする。アカウントのクローズ・組織の解散等の
実際のAWS操作は対象外とし、Issue #14の別の手順として個別に実施する。

## 2. 前提条件

- 本番アカウントに対してTerraform Cloud（OIDC連携）でapply可能な状態であること
- 本番アカウント上でIAM Identity Center（アカウントインスタンス）が有効化済みであること（Issue #14の別手順で実施）
- SSMパラメータ `/org/sso/users` の `groups` に `DevelopmentUsers` を指定しているユーザーが存在しないこと
  （本改修で開発環境向けグループ・権限セットを廃止したため）

## 3. 手順

### 3.1. Terraformコードの静的検証

```bash
cd terraform
terraform fmt -recursive
terraform validate
```

### 3.2. Terraform Cloudでのplan確認

本PRをGitHubにプッシュすると、Terraform CloudのVCS-driven WorkflowによりPlanが自動実行される。
以下の内容がPlan結果に含まれることを確認する。

- 削除: `aws_organizations_organization`、`aws_organizations_organizational_unit`（本番用・開発用の2件）、
  `aws_organizations_policy`（リージョン制限・ルート操作ブロック・ガバナンス保護の3件）、
  `aws_organizations_account.member_accounts`、開発環境向けの権限セット・グループ・アカウント割り当て
- 変更: `aws_accessanalyzer_analyzer.accessanaly` の `type` を `ORGANIZATION` から `ACCOUNT` に変更
- 追加: なし（CloudTrailはデフォルトのEvent historyを利用するため、Trail・S3バケットは構築しない）

### 3.3. apply

Plan結果に想定外の削除・変更が含まれないことを確認したうえで、PRをマージしTerraform Cloud上でapplyを実行する。

### 3.4. 動作確認

- IAM Access Analyzerがアカウントタイプで有効化されていることを確認する
- Budgets・SNS通知・EventBridgeが従来通り機能することを確認する
- IAM Identity CenterのAdministrators・ProductionUsersグループが本番アカウントに割り当てられ、
  ログインできることを確認する
