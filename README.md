# AWS組織管理リポジトリ

## 概要

このリポジトリは、Terraformを用いてAWS Organizations環境をコードとして管理（Infrastructure as Code）します。

AWS Systems Manager パラメータストアに定義された情報に基づき、AWSアカウントやIAM Identity Centerのユーザーと権限を動的にプロビジョニングします。手作業によるヒューマンエラーを削減し、再現性のあるインフラ構成を迅速に展開することを目的としています。

インフラの変更はすべてGitHub上でのレビューを経て自動的に適用されるVCS-driven Workflowを採用しています。

### 主な管理対象

- AWS Organizations (OU, SCP)
- AWS IAM Identity Center (ユーザー、グループ、権限セット、アカウント割り当て)
- AWS Budgets
- その他セキュリティ関連サービス (CloudTrail, IAM Access Analyzer等)

## システム構成

- **IaC:** Terraform
- **設定情報のソース:** AWS Systems Manager パラメータストア
- **CI/CD:** Terraform Cloud (VCS-driven Workflow)
- **VCS:** GitHub
- **認証:** Terraform CloudとAWS IAMのOIDC連携

## 運用手順

**重要:** AWSアカウントやユーザーに関する操作は、Terraformのコード（`.tf`ファイル）を直接編集するのではなく、AWS Systems Managerの**パラメータストア**を更新することで行います。

### 新規AWSアカウントの作成手順

1.  **パラメータストアを開く:**
    - AWSマネジメントコンソールにログインし、**AWS Systems Manager** > **パラメータストア** を開きます。
    - `/org/accounts` という名前のパラメータを選択します。

2.  **パラメータ値を編集:**
    - 「パラメータを編集」ボタンを押し、値のJSONを更新します。
    - 既存のJSON配列 `[...]` の中に、新しいアカウント情報をオブジェクトとして追記します。

    **JSONオブジェクトのフォーマット:**
    ```json
    {
      "name": "NewProjectAccount",
      "email": "aws-new-project@example.com",
      "ou_name": "dev"
    }
    ```
    - `name`: 新しいAWSアカウント名
    - `email`: 既存のAWSアカウントで使用されていない一意のメールアドレス
    - `ou_name`: 所属させたいOUの短い名前 (`dev` または `prd`)

3.  **変更を保存:**
    - JSONの編集後、「変更を保存」をクリックします。

4.  **Terraformを適用:**
    - Terraform Cloudのワークスペース（`aws-admin-cmn`）に移動します。
    - 「Start new run」を開始し、`terraform apply` を実行します。これにより、Terraformがパラメータストアの変更を検知し、新しいAWSアカウントが作成されます。

### 新規ユーザーの作成と権限付与の手順

ユーザーの作成とグループへの所属は、単一のパラメータ `/org/sso/users` で管理します。権限はユーザーが所属するグループ（`Administrators`, `ProductionUsers`, `DevelopmentUsers`）に対して付与されます。

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
      "groups": ["DevelopmentUsers"]
    }
    ```
    - `familyName`: 姓
    - `givenName`: 名
    - `email`: ユーザーのメールアドレス（これがIAM Identity Centerでのユーザー名になります）
    - `groups`: 所属させたいグループ名の配列。指定可能な値は `Administrators`, `ProductionUsers`, `DevelopmentUsers` です。

3.  **変更を保存:**
    - JSONの編集後、「変更を保存」をクリックします。

4.  **Terraformを適用:**
    - Terraform Cloudのワークスペースで新しいRunを開始し、`terraform apply` を実行します。
    - Terraformがパラメータストアの変更を検知し、IAM Identity Centerに新しいユーザーが作成され、指定されたグループに所属します。グループに割り当てられた権限が、このユーザーに自動的に適用されます。