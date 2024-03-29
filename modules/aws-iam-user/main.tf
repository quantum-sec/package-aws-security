terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.49.0"
    }
  }
}

resource "aws_iam_user" "user" {
  name                 = var.name
  path                 = var.path
  force_destroy        = var.force_destroy
  permissions_boundary = var.permissions_boundary_policy_arn
  tags                 = var.tags
}

resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = var.attached_policy_arns

  user       = aws_iam_user.user.name
  policy_arn = each.value
}
