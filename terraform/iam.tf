resource "aws_accessanalyzer_analyzer" "iamanaly" {
  analyzer_name = "${var.system_name}-${var.env}-iamanaly"
  type          = "ORGANIZATION" # アカウントのみを対象にする場合は "ACCOUNT" を指定

  tags = {
    Name        = "${var.system_name}-${var.env}-iamanaly",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}