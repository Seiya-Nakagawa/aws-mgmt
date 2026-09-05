# Access Analyzer（本番アカウント単体のアカウントタイプ）
resource "aws_accessanalyzer_analyzer" "accessanaly" {
  analyzer_name = "${var.system_name}-${var.env}-accessanaly"
  type          = "ACCOUNT"

  tags = {
    Name       = "${var.system_name}-${var.env}-accessanaly",
    SystemName = var.system_name,
    Env        = var.env,
  }
}