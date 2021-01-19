# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A CUSTOMER MASTER KEY (CMK) IN KMS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12.26"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE THE CUSTOMER MASTER KEY
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "master_key" {
  description              = "The ${var.name} customer master key."
  policy                   = data.aws_iam_policy_document.policy.json
  deletion_window_in_days  = var.deletion_window_in_days
  customer_master_key_spec = var.customer_master_key_spec
  enable_key_rotation      = var.enable_key_rotation
  tags                     = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "policy" {

  # Allow the root account full access to allow IAM-controlled CMK permissions.
  statement {
    sid       = "AllowRootAccountFullAccess"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }

  # Allow service principals specific access to the CMK.
  dynamic "statement" {
    for_each = var.service_principals

    content {
      sid = "AllowServicePrincipalAccess-${md5(jsonencode(statement.value))}"

      effect    = "Allow"
      resources = ["*"]

      actions = statement.value.actions

      principals {
        type        = "Service"
        identifiers = [statement.value.name]
      }

      dynamic "condition" {
        for_each = coalesce(statement.value.conditions, [])

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE AN ALIAS FOR THE CMK
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_kms_alias" "master_key" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.master_key.id
}