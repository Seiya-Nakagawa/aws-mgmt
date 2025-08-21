resource "aws_sns_topic" "sns_topic_awschat" {
  name = "${var.system_name}-${var.env}-sns-awschat"

  tags = {
    Name       = "${var.system_name}-${var.env}-sns-awschat",
    SystemName = var.system_name,
    Env        = var.env,
  }
}