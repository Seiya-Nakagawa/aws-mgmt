# 02 構築手順書 - 本番アカウント直下へのIAM Identity Center構築

## 目次

- [1. 概要](#1-概要)
- [2. 前提条件](#2-前提条件)
- [3. 手順](#3-手順)
  - [3.1. IAM Identity Centerのアカウントインスタンス有効化（手動）](#31-iam-identity-centerのアカウントインスタンス有効化手動)
  - [3.2. Terraform Cloudワークスペース変数の設定](#32-terraform-cloudワークスペース変数の設定)
  - [3.3. Terraformコードの静的検証](#33-terraformコードの静的検証)
  - [3.4. Terraform Cloudでのplan確認](#34-terraform-cloudでのplan確認)
  - [3.5. apply](#35-apply)
  - [3.6. SSO経由でのログイン確認](#36-sso経由でのログイン確認)

## 1. 概要

Issue #19（Issue #14の対応の一部）として、本番アカウント直下にIAM Identity Center
（アカウントインスタンス）を新規構築し、管理者ユーザー・管理者用許可セットを作成して
SSO経由でログインできることを確認する。

IAM Identity Centerのアカウントインスタンス自体の有効化に対応するTerraformリソースは
存在しないため、[3.1節](#31-iam-identity-centerのアカウントインスタンス有効化手動)は
AWSマネジメントコンソールでの手動操作となる。有効化後の許可セット・ユーザー・
アカウント割り当てはTerraformで管理する。

本番アカウントがまだAWS Organizationsのメンバーである間は、Terraform Cloudワークスペースの
認証情報（管理アカウント）から`OrganizationAccountAccessRole`へassume_roleすることで、
本番アカウント直下にリソースを構築する（[基本設計書 2.4.1](../【AWS組織管理】基本設計書.md#241-本番アカウント移行期の認証一時的な措置)参照）。

## 2. 前提条件

- 本番アカウントがAWS Organizationsのメンバーであり、`OrganizationAccountAccessRole`が
  存在すること
- Terraform Cloudワークスペース（`aws-mgmt-cmn`）のOIDC連携が管理アカウントに対して有効であること
- 管理アカウントの管理者権限を持つAWSマネジメントコンソールアクセスがあること
  （`OrganizationAccountAccessRole`へのスイッチロールに使用する）

## 3. 手順

### 3.1. IAM Identity Centerのアカウントインスタンス有効化（手動）

1. 管理アカウントのAWSマネジメントコンソールにログインする
2. 本番アカウント（アカウントID: Terraform変数`production_account_id`の値）へ
   `OrganizationAccountAccessRole`でスイッチロールする
3. リージョンを東京（`ap-northeast-1`）に切り替える
4. **IAM Identity Center**のコンソールを開く
5. 「有効化」を選択する。組織インスタンスではなく**アカウントインスタンス**として
   有効化されることを確認する（本番アカウントは引き続きOrganizationsのメンバーだが、
   管理アカウント側で組織インスタンスを有効化していないため、アカウント単体の
   インスタンスとして有効化される）
6. 有効化直後に表示される**AWSアクセスポータルのURL**（`https://xxxxxxxxxx.awsapps.com/start`
   の形式）を控えておく（[3.6節](#36-sso経由でのログイン確認)で使用する）

   > 有効化に失敗し「組織の管理者がアカウントインスタンスの作成を無効にしています」
   > といった趣旨のエラーが表示される場合、2023年11月15日より前に組織でIAM Identity Center
   > を有効化した組織に適用されるデフォルト制限に該当している可能性がある。その場合は
   > 管理アカウント側でアカウントインスタンスの作成を許可する設定が必要となるため、
   > 対応方法を別途確認すること。

### 3.2. Terraform Cloudワークスペース変数の設定

ワークスペース（`aws-mgmt-cmn`）に以下の変数を設定する。いずれもメールアドレス・氏名という
個人情報を含むため、**Sensitive**変数として設定する。

| Terraform変数名 | 説明 |
| :--- | :--- |
| `admin_email` | 管理者ユーザーのメールアドレス（SSOのユーザー名になる） |
| `admin_given_name` | 管理者ユーザーの名 |
| `admin_family_name` | 管理者ユーザーの姓 |

### 3.3. Terraformコードの静的検証

```bash
cd terraform
terraform fmt -recursive
terraform validate
```

### 3.4. Terraform Cloudでのplan確認

本PRをGitHubにプッシュすると、Terraform CloudのVCS-driven WorkflowによりPlanが実行される。
PRに対する自動Planが発火しない場合は、Terraform CloudのAPIから直接plan-onlyランを作成して
確認する。以下の内容がPlan結果に含まれることを確認する。

- 追加: `aws_ssoadmin_permission_set.ssopermsets_administrator_production`、
  `aws_ssoadmin_managed_policy_attachment.ssopermsets_administrator_production_policy`、
  `aws_identitystore_user.admin_production`、
  `aws_ssoadmin_account_assignment.admin_account_assignment_production`
- 削除・変更: なし（既存の管理アカウント側リソースへの影響はない想定）
- `data.aws_ssoadmin_instances.sso_instances_production`が空を返す場合、
  [3.1節](#31-iam-identity-centerのアカウントインスタンス有効化手動)の有効化が
  完了していないか、assume_role先のリージョンが東京になっていない

### 3.5. apply

Plan結果に想定外の削除・変更が含まれないことを確認したうえで、PRをマージしTerraform Cloud上で
applyを実行する。

### 3.6. SSO経由でのログイン確認

1. [3.1節](#31-iam-identity-centerのアカウントインスタンス有効化手動)で控えた
   AWSアクセスポータルのURLにアクセスする
2. 管理者ユーザー（`admin_email`で指定したメールアドレス）で初回サインインを行い、
   届いた招待メールの案内に従ってパスワードを設定する
3. アクセスポータル上に本番アカウントと管理者用許可セットが表示され、
   本番アカウントのマネジメントコンソールにAdministratorAccess権限でログインできることを確認する
