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

resource "aws_sns_topic_policy" "sns_topic_policy_awschat" {
  arn    = aws_sns_topic.sns_topic_awschat.arn
  policy = data.aws_iam_policy_document.sns_topic_policy_document_awschat.json
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
