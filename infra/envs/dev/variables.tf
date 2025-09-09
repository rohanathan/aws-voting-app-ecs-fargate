variable "project" { default = "task007-ecs" }
variable "env" { default = "dev" }
variable "region" { default = "eu-west-2" }

# image tags 
variable "image_tags" {
  type = map(string)
  default = {
    frontend    = "latest"
    vote_api    = "latest"
    results_api = "latest"
    worker      = "latest"
  }
}
