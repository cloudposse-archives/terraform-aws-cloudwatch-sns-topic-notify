locals {
  parameter_name = "/${var.namespace}/${var.stage}/${var.name}/Terraform-SNS-Trigger-Hash"
}

data "aws_caller_identity" "default" {}

resource "aws_ssm_parameter" "default" {
  name        = "${local.parameter_name}"
  description = "Force an SNS event via cloudwatch and Parameter Store for ${module.label.id}"
  type        = "String"
  value       = "${var.trigger_hash}"
  tags        = "${var.tags}"
  depends_on  = ["aws_cloudwatch_event_rule.default", "aws_sns_topic_policy.default"]
}

resource "aws_cloudwatch_event_rule" "default" {
  name        = "${module.label.id}-sns-notify"
  description = "Force an SNS event via cloudwatch and Parameter Store for ${module.label.id}"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ssm"
  ],
  "detail-type": [
    "Parameter Store Change"
  ],
  "detail": {
    "operation": ["Update", "Create"],
    "name": ["${local.parameter_name}"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sns" {
  rule       = "${aws_cloudwatch_event_rule.default.name}"
  target_id  = "SendToSNS"
  arn        = "${var.sns_topic_arn}"
  depends_on = ["aws_cloudwatch_event_rule.default"]
  input      = "${var.sns_message_override}"
}

resource "aws_sns_topic_policy" "default" {
  count  = "${var.add_events_to_sns_policy == "true" ? 1 : 0}"
  arn    = "${var.sns_topic_arn}"
  policy = "${data.aws_iam_policy_document.sns_topic_policy.0.json}"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count     = "${var.add_events_to_sns_policy == "true" ? 1 : 0}"
  policy_id = "__default_policy_ID"

  statement {
    sid = "__default_statement_ID"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect    = "Allow"
    resources = ["${var.sns_topic_arn}"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:root",
      ]
    }
  }

  statement {
    sid       = "Allow CloudwatchEvents"
    actions   = ["sns:Publish"]
    resources = ["${var.sns_topic_arn}"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

output "parameter_name" {
  value = "${local.parameter_name}"
}

output "trigger_hash" {
  value = "${var.trigger_hash}"
}

output "cloudwatch_event_rule_name" {
  value = "${aws_cloudwatch_event_rule.default.name}"
}

output "sns_topic_arn" {
  value = "${var.sns_topic_arn}"
}
