# Chatbot用のCloudWatchロググループ
resource "aws_cloudwatch_log_group" "loggroup_chatbot" {
  # Chatbotが期待する命名規則に従って名前を定義
  name = "/aws/chatbot/chat-configurations/${var.system_name}-${var.env}-chatbot-slack"

  # ログの保持期間（例: 30日）を設定。設定しない場合は無期限になります。
  retention_in_days = 1

  tags = {
    Name        = "${var.system_name}-${var.env}-loggroup-chatbot",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}