variable "sns_topic_arn" {
  description = "The SNS topic arn to update"
  type        = "string"
}

variable "trigger_hash" {
  description = "A value that can be changed to trigger the notification of the SNS topic"
  default     = "none"
}

variable "sns_message_override" {
  description = "An SNS JSON payload to pass to SNS"
  default     = ""
}

variable "add_events_to_sns_policy" {
  type        = "string"
  description = "If set to 'true' then the extra policy required for allowing CloudWatch events is combined with the default sns policy and added to the SNS topic arns, in the same way that cloudwatch does through the console."
  default     = "true"
}
