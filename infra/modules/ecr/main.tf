locals { names = toset(var.repo_names) }

resource "aws_ecr_repository" "repos" {
  for_each = local.names
  name     = "${var.project}-${each.value}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

