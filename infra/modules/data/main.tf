resource "aws_sqs_queue" "votes" {
  name = "${var.project}-${var.env}-votes"
}

resource "aws_dynamodb_table" "ratings" {
  name         = "${var.project}_${var.env}_emoji_ratings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "item"
  attribute {
     name="item" 
     type="S" 
     }
}

