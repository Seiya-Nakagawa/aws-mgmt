resource "aws_sns_topic" "sns_topic_awschat" {
  name              = "${var.system_name}-${var.env}-sns-awschat"
  display_name      = "${var.system_name}-${var.env}-sns-awschat"
  kms_master_key_id = "alias/aws/sns"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
  tags = {
    Name            = "${var.system_name}-${var.env}-sns-awschat",
    SystemName      = var.system_name,
    Env             = var.env,
  }
}

resource "aws_sns_topic_policy" "sns_topic_awschat_policy" {
  arn    = aws_sns_topic.sns_topic_awschat.arn
  policy = data.aws_iam_policy_document.sns_topic_awschat_policy_document.json
}

data "aws_iam_policy_document" "sns_topic_awschat_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive",
    ]
    resources = [
      aws_sns_topic.sns_topic_awschat.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_data_protection_policy" "sns_topic_awschat_data_protection_policy" {
  arn = aws_sns_topic.sns_topic_awschat.arn
  policy = jsonencode({
    "Name"        = "data_protection_policy"
    "Description" = "Enable data protection policy"
    "Version"     = "2021-06-01"
    "Statement" = [
      {
        "Sid"           = "EnableDataProtection"
        "DataDirection" = "Inbound"
        "Principal"     = ["*"]
        "DataIdentifier" = [
          "arn:aws:dataprotection::aws:data-identifier/Address",
        ]
        "Operation" = {
          "Deny" = {}
        }
      }
    ]
  })
}
