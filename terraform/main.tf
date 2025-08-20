# `terraform_data`を使って、リソースの作成日時を記録
resource "terraform_data" "creation_time" {
  # このリソースが再作成された時に、inputも再評価される
  triggers_replace = [
    aws_accessanalyzer_analyzer.iamanaly.id
  ]

  input = terraform_data.creation_time.input
}
