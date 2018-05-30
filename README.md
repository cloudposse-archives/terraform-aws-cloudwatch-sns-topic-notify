# terraform-aws-sns-topic-notify

Terraform doesn't have the ability to invoke an AWS Lambda function directly or to Notify an AWS SNS Topic.

This module solves the issue of notifying an SNS topic.

It was built so that after creating CodePipelines, and Lambda Functions that subscribe to SNS queue, they could be triggered immediately by native Terraform.


To trigger the SNS notification this module uses:

- SSM Parameter Store
- Cloudwatch Event Rule
- Cloudwatch Event Target
- SNS Policy

The Cloudwatch rule is created with a filter to watch for the creation or update of a single SSM Parameter name.
The SNS Policy is updated to allow for Notification from CloudWatch to be accepted.
The Cloudwatch Event Taget is set to the ARN of the SNS Topic provided.

When the value of the parameter created or updated, the SNS Topic is notified.


## Example 1: Create Lambda Function, make SNS topic, subscribe to it and trigger it

```hcl
# Zip up Lambda Function
data "archive_file" "lambda_update_asg" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda-update-autoscaling-groups.py"
  output_path = "${path.module}/lambda/lambda-update-autoscaling-groups.zip"
}

# Release Lambda Function
resource "aws_lambda_function" "lambda_update_asg" {
  filename         = "${data.archive_file.lambda_update_asg.output_path}"
  function_name    = "${module.label.id}-update-asg"
  role             = "${aws_iam_role.role.arn}"
  handler          = "lambda-update-autoscaling-groups.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_update_asg.output_base64sha256}"
  runtime          = "python2.7"
  tags             = "${module.label.tags}"
  timeout          = "15"

  kms_key_arn = "${var.kms_key_arn}"
}

# Make SNS topic
resource "aws_sns_topic" "default" {
  name_prefix = "Automation-Trigger"
}

# Subscribe the Lambda Function to the Topic
resource "aws_sns_topic_subscription" "lambda_update_asg" {
  topic_arn = "${aws_sns_topic.default.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lambda_update_asg.arn}"
}

# Send a notification to the topic <--- This Module
module "notify" {
  source        = "git::https://github.com/bitflight-public/terraform-aws-sns-topic-notify.git?ref=master"
  namespace     = "cp"
  stage         = "staging"
  name          = "lambda-update-asg"
  sns_topic_arn = "${aws_sns_topic.default.arn}"
  trigger_hash  = "${aws_lambda_function.lambda_update_asg.source_code_hash}"
}
```


## Variables

| Name                            |                    Default                     | Description                                                                                            | Required |
|:--------------------------------|:----------------------------------------------:|:-------------------------------------------------------------------------------------------------------|:--------:|
| `namespace`                     |                       ``                       | Namespace (e.g. `cp` or `cloudposse`)                                                                  |   Yes    |
| `stage`                         |                       ``                       | Stage (e.g. `prod`, `dev`, `staging`                                                                   |   Yes    |
| `name`                          |                       ``                       | Name  (e.g. `bastion` or `db`)                                                                         |   Yes    |
| `attributes`                    |                      `[]`                      | Additional attributes (e.g. `policy` or `role`)                                                        |    No    |
| `tags`                          |                      `{}`                      | Additional tags  (e.g. `map("BusinessUnit","XYZ")`                                                     |    No    |
| `sns_topic_arn`                 |                       ``                       | The SNS Topic ARN to Notify                                                    											  |   Yes    |
| `trigger_hash`                  |                       ``                       | A hash of any value that changes only when you want to notify the SNS topic                            |   Yes    |
| `sns_message_override`          |                      `""`                      | AAn SNS JSON payload to pass to SNS 																				                            |    No    |
| `add_events_to_sns_policy`      |                    `"true"`                    | Updates the SNS policy on the topic to allow CloudWatch Events to notify the topic                     |    No    |

