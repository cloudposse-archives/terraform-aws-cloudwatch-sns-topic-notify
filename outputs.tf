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
