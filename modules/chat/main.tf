data "aws_region" "current" {}

resource "aws_dynamodb_table" "messages" {
  name         = "${var.app_name}-chat-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "channel"
  range_key    = "ts"

  attribute {
    name = "channel"
    type = "S"
  }

  attribute {
    name = "ts"
    type = "S"
  }
}
