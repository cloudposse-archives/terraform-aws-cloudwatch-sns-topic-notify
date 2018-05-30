### For connecting and provisioning
variable "region" {
  default = "ap-southeast-2"
}

provider "aws" {
  region = "${var.region}"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

# Make a topic
resource "aws_sns_topic" "default" {
  name_prefix = "Automation-Trigger"
}

# Generate a random hash, but the hash could be the sha256 of a lambda function easily enough.
resource "random_string" "unique" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = false
}

# Send a notification to the topic
module "notify" {
  source        = "../"
  namespace     = "cp"
  stage         = "staging"
  name          = "lambda-trigger-automation"
  sns_topic_arn = "${aws_sns_topic.default.arn}"
  trigger_hash  = "${random_string.unique.result}"
}

# Output the outputs
output "sns_topics" {
  value = "${aws_sns_topic.default.arn}"
}

output "parameter_name" {
  value = "${module.notify.parameter_name}"
}

output "trigger_hash" {
  value = "${random_string.unique.result}"
}
