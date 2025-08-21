resource "aws_accessanalyzer_analyzer" "accessanaly" {
  analyzer_name = "${var.system_name}-${var.env}-accessanaly"
  type          = "ORGANIZATION"

  tags = {
    Name        = "${var.system_name}-${var.env}-accessanaly",
    SystemName  = var.system_name,
    Env         = var.env,
  }
}

# AWS Chatbot用ロール
resource "aws_iam_role" "iamrole_chatbot" {
  name = "${var.system_name}-${var.env}-iamrole-chatbot"

  # ChatbotサービスからのAssumeRoleを許可する信頼ポリシー
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "chatbot.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# AWS Chatbot用ポリシー
resource "aws_iam_policy" "iampolicy_chatbot" {
  name        = "${var.system_name}-${var.env}-iampolicy-chatbot"
  description = "Allows AWS Chatbot to write logs to CloudWatch Logs"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_account_id}:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iampolicy_chatbot_attach" {
  role       = aws_iam_role.iamrole_chatbot.name
  policy_arn = aws_iam_policy.iampolicy_chatbot.arn
}