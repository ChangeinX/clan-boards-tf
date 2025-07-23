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

resource "aws_dynamodb_table" "chat" {
  name         = "${var.app_name}-chat"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "SK"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
