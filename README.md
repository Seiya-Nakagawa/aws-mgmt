# AWS組織管理リポジトリ

## 概要

このリポジトリは、Terraformを用いて本番アカウント単体のAWS基盤をコードとして管理（Infrastructure as Code）します。

AWS Systems Manager パラメータストアに定義された情報に基づき、IAM Identity Centerのユーザーと権限を動的にプロビジョニングします。手作業によるヒューマンエラーを削減し、再現性のあるインフラ構成を迅速に展開することを目的としています。

インフラの変更はすべてGitHub上でのレビューを経て自動的に適用されるVCS-driven Workflowを採用しています。

### 主な管理対象

- AWS IAM Identity Center（アカウントインスタンス。ユーザー、グループ、権限セット、アカウント割り当て）
- AWS Budgets
- その他セキュリティ関連サービス (CloudTrail、IAM Access Analyzer等、いずれも本番アカウント単体のアカウントレベル機能)

## システム構成

- **IaC:** Terraform
- **設定情報のソース:** AWS Systems Manager パラメータストア
- **CI/CD:** Terraform Cloud (VCS-driven Workflow)
- **VCS:** GitHub
- **認証:** Terraform CloudとAWS IAMのOIDC連携

## 運用手順

**重要:** ユーザーに関する操作は、Terraformのコード（`.tf`ファイル）を直接編集するのではなく、AWS Systems Managerの**パラメータストア**を更新することで行います。

### 新規ユーザーの作成と権限付与の手順

ユーザーの作成とグループへの所属は、単一のパラメータ `/org/sso/users` で管理します。権限はユーザーが所属するグループ（`Administrators`, `ProductionUsers`）に対して付与されます。

1.  **パラメータストアを開く:**
    - AWS Systems Manager > パラメータストア を開きます。
    - `/org/sso/users` という名前のパラメータを選択します。

2.  **パラメータ値を編集:**
    - 「パラメータを編集」ボタンを押し、値のJSONを更新します。
    - 既存のJSON配列 `[...]` の中に、新しいユーザー情報をオブジェクトとして追記します。

    **JSONオブジェクトのフォーマット:**
    ```json
    {
      "familyName": "Nakamura",
      "givenName": "Taro",
      "email": "taro.nakamura@example.com",
      "groups": ["ProductionUsers"]
    }
    ```
    - `familyName`: 姓
    - `givenName`: 名
    - `email`: ユーザーのメールアドレス（これがIAM Identity Centerでのユーザー名になります）
    - `groups`: 所属させたいグループ名の配列。指定可能な値は `Administrators`, `ProductionUsers` です。

3.  **変更を保存:**
    - JSONの編集後、「変更を保存」をクリックします。

4.  **Terraformを適用:**
    - Terraform Cloudのワークスペースで新しいRunを開始し、`terraform apply` を実行します。
    - Terraformがパラメータストアの変更を検知し、IAM Identity Centerに新しいユーザーが作成され、指定されたグループに所属します。グループに割り当てられた権限が、このユーザーに自動的に適用されます。