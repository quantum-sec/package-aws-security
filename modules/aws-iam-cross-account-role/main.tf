# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A CROSS-ACCOUNT IAM ROLE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.49.0"
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.remote_account_number}:root"]
    }

    condition {
      test = "StringEquals"
      values = [
        var.external_id
      ]
      variable = "sts:ExternalId"
    }
  }
}

resource "aws_iam_role" "role" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "policy" {
  for_each   = var.iam_policy_arns
  role       = aws_iam_role.role.id
  policy_arn = each.value
}
