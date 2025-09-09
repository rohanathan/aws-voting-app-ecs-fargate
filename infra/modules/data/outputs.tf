output "sqs_queue_url" { value = aws_sqs_queue.votes.id }   # URL
output "sqs_queue_arn" { value = aws_sqs_queue.votes.arn }
output "ddb_table"     { value = aws_dynamodb_table.ratings.name }
output "ddb_arn"       { value = aws_dynamodb_table.ratings.arn }
