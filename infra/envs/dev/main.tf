terraform {
  required_version = ">=1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~>5.0" } }
}

provider "aws" { region = var.region }

# Single ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-${var.env}-cluster"
}

# Network (VPC and ALB SG)
module "network" {
  source  = "../../modules/network"
  project = var.project
  env     = var.env
  region  = var.region
}

# ALB
module "alb" {
  source            = "../../modules/alb"
  project           = var.project
  env               = var.env
  public_subnet_ids = module.network.public_subnets
  alb_sg_id         = module.network.alb_sg_id
}

# Logs
module "logs" {
  source = "../../modules/logs"
  name   = "/ecs/${var.project}-${var.env}"
}

# Data plane (SQS and DynamoDB)
module "data" {
  source  = "../../modules/data"
  project = var.project
  env     = var.env
}

# ECR repos
module "ecr" {
  source     = "../../modules/ecr"
  project    = var.project
  repo_names = ["frontend", "vote-api", "results-api", "worker"]
}



module "iam_frontend" {
  source = "../../modules/iam-task"
  name   = "${var.project}-${var.env}-frontend"
}

# vote-api needing SQS:SendMessage
module "iam_vote" {
  source = "../../modules/iam-task"
  name   = "${var.project}-${var.env}-vote"
  policy_json = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["sqs:SendMessage"], Resource = module.data.sqs_queue_arn }]
  })
}

# worker needing SQS receive/delete and DynamoDB update
module "iam_worker" {
  source = "../../modules/iam-task"
  name   = "${var.project}-${var.env}-worker"
  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], Resource = module.data.sqs_queue_arn },
      { Effect = "Allow", Action = ["dynamodb:UpdateItem"], Resource = module.data.ddb_arn }
    ]
  })
}

# results-api needs DynamoDB scan
module "iam_results" {
  source = "../../modules/iam-task"
  name   = "${var.project}-${var.env}-results"
  policy_json = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["dynamodb:Scan"], Resource = module.data.ddb_arn }]
  })
}

# ECS services each creates TG+rule+service+SG
# Running services in private subnets as NAT is enabled in network module

module "svc_frontend" {
  source             = "../../modules/ecs-service"
  project            = var.project
  env                = var.env
  region             = var.region
  name               = "${var.project}-${var.env}-frontend"
  image              = "${module.ecr.repo_urls["frontend"]}:${var.image_tags["frontend"]}"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnets
  assign_public_ip   = false
  execution_role_arn = module.iam_frontend.execution_role_arn
  task_role_arn      = module.iam_frontend.task_role_arn
  log_group          = module.logs.log_group_name
  listener_arn       = module.alb.listener_arn
  alb_sg_id          = module.network.alb_sg_id
  path_patterns      = ["/*"]
  priority           = 200

  cluster_arn  = aws_ecs_cluster.cluster.arn
  cluster_name = aws_ecs_cluster.cluster.name

  enable_autoscaling = true
  min_count          = 2
  max_count          = 4
}

module "svc_vote_api" {
  source             = "../../modules/ecs-service"
  project            = var.project
  env                = var.env
  region             = var.region
  name               = "${var.project}-${var.env}-vote"
  image              = "${module.ecr.repo_urls["vote-api"]}:${var.image_tags["vote_api"]}"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnets
  assign_public_ip   = false
  execution_role_arn = module.iam_vote.execution_role_arn
  task_role_arn      = module.iam_vote.task_role_arn
  log_group          = module.logs.log_group_name
  listener_arn       = module.alb.listener_arn
  alb_sg_id          = module.network.alb_sg_id
  path_patterns      = ["/api/vote*", "/api/vote/*"]
  priority           = 110
  environment        = { SQS_QUEUE_URL = module.data.sqs_queue_url }

  cluster_arn  = aws_ecs_cluster.cluster.arn
  cluster_name = aws_ecs_cluster.cluster.name

  enable_autoscaling = true
  min_count          = 2
  max_count          = 4
}

module "svc_results_api" {
  source             = "../../modules/ecs-service"
  project            = var.project
  env                = var.env
  region             = var.region
  name               = "${var.project}-${var.env}-results"
  image              = "${module.ecr.repo_urls["results-api"]}:${var.image_tags["results_api"]}"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnets
  assign_public_ip   = false
  execution_role_arn = module.iam_results.execution_role_arn
  task_role_arn      = module.iam_results.task_role_arn
  log_group          = module.logs.log_group_name
  listener_arn       = module.alb.listener_arn
  alb_sg_id          = module.network.alb_sg_id
  path_patterns      = ["/api/results*", "/api/results/*"]
  priority           = 120
  environment        = { DDB_TABLE = module.data.ddb_table }

  cluster_arn  = aws_ecs_cluster.cluster.arn
  cluster_name = aws_ecs_cluster.cluster.name

  enable_autoscaling = true
  min_count          = 2
  max_count          = 4
}

module "svc_worker" {
  source             = "../../modules/ecs-service"
  project            = var.project
  env                = var.env
  region             = var.region
  name               = "${var.project}-${var.env}-worker"
  image              = "${module.ecr.repo_urls["worker"]}:${var.image_tags["worker"]}"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnets
  assign_public_ip   = false
  execution_role_arn = module.iam_worker.execution_role_arn
  task_role_arn      = module.iam_worker.task_role_arn
  log_group          = module.logs.log_group_name
  listener_arn       = module.alb.listener_arn
  alb_sg_id          = module.network.alb_sg_id
  path_patterns      = ["/__bg-worker__"]
  priority           = 130
  desired_count      = 1
  environment        = { DDB_TABLE = module.data.ddb_table, SQS_QUEUE_URL = module.data.sqs_queue_url }

  cluster_arn  = aws_ecs_cluster.cluster.arn
  cluster_name = aws_ecs_cluster.cluster.name

  attach_to_alb      = false
  enable_autoscaling = false
}
