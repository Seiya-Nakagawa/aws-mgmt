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

# AWS Chatbot用ロール
resource "aws_iam_role" "iamrole_chatbot" {
  name = "${var.system_name}-${var.env}-iamrole-chatbot"

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
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.loggroup_chatbot.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iampolicy_chatbot_attach" {
  role       = aws_iam_role.iamrole_chatbot.name
  policy_arn = aws_iam_policy.iampolicy_chatbot.arn
}

# --- SNS配信ステータスログ用 --- 
# SNSがCloudWatch Logsに書き込むための権限を定義するIAMポリシー
resource "aws_iam_policy" "sns_delivery_status_logging_policy" {
  name        = "sns-delivery-status-logging-policy"
  description = "Allows SNS to write delivery status logs to CloudWatch"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = [
          aws_cloudwatch_log_group.sns_topic_awschat_log_group.arn
        ]
      }
    ]
  })
}

# SNSサービスが引き受けるためのIAMロール
resource "aws_iam_role" "sns_delivery_status_logging_role" {
  name               = "sns-delivery-status-logging-role"
  description        = "Role for SNS to log delivery status to CloudWatch"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 作成したポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "sns_delivery_status_logging_attachment" {
  role       = aws_iam_role.sns_delivery_status_logging_role.name
  policy_arn = aws_iam_policy.sns_delivery_status_logging_policy.arn
}