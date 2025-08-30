# Access Analyzer
resource "aws_accessanalyzer_analyzer" "accessanaly" {
  analyzer_name = "${var.system_name}-${var.env}-accessanaly"
  type          = "ORGANIZATION"

  tags = {
    Name        = "${var.system_name}-${var.env}-accessanaly",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}