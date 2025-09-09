terraform {
  backend "s3" {
    bucket       = "tf-state-09082025" 
    key          = "aws-mvp/dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt        = true
  }
}
