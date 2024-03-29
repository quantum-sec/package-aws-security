# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN IAM ROLE
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

locals {
  create_policies = {
    for key, value in local.policies : key => value if value.policy != null
  }
  policies = {
    # exclude any policies matching values in the `excluded_policy_names` list.
    for key, value in local.merged_policies : key => value if !contains(var.excluded_policy_names, key)
  }
  merged_policies = merge(local.included_default_policies, var.policy_custom)
  included_default_policies = {
    # include any policies matching values in the `included_default_policy_names` list.
    for key, value in local.default_policies : key => value if contains(var.included_default_policy_names, key)
  }

  default_policies = {
    auto_deploy_from_external_accounts = {
      name                 = var.auto_deploy_policy == null ? "auto-deploy-from-external-accounts" : lookup(var.auto_deploy_policy, "name", "auto-deploy-from-external-accounts")
      description          = var.auto_deploy_policy == null ? "The policy providing access for automation of deployments from external accounts" : lookup(var.auto_deploy_policy, "description", "The policy providing access for automation of deployments from external accounts")
      path                 = var.auto_deploy_policy == null ? var.default_path : lookup(var.auto_deploy_policy, "path", var.default_path)
      policy               = var.auto_deploy_policy == null ? data.aws_iam_policy_document.auto_deploy_from_external_accounts.json : lookup(var.auto_deploy_policy, "policy", data.aws_iam_policy_document.auto_deploy_from_external_accounts.json)
      service_principals   = setunion(var.auto_deploy_policy == null ? [] : lookup(var.auto_deploy_policy, "service_principals", []), local.auto_deploy_service_principals)
      aws_principals       = var.auto_deploy_policy == null ? var.auto_deploy_from_accounts : lookup(var.auto_deploy_policy, "aws_principals", [])
      federated_principals = var.auto_deploy_policy == null ? [] : lookup(var.auto_deploy_policy, "federated_principals", [])
      iam_policy_arns      = var.auto_deploy_policy == null ? [] : lookup(var.auto_deploy_policy, "iam_policy_arns", [])
      role_requires_mfa    = var.auto_deploy_policy == null ? false : lookup(var.auto_deploy_policy, "role_requires_mfa", false)
    }
    developer_from_external_accounts = {
      name                 = var.developer_policy == null ? "developer-from-external-accounts" : lookup(var.developer_policy, "name", "developer-from-external-accounts")
      description          = var.developer_policy == null ? "The policy providing access for developer" : lookup(var.developer_policy, "description", "The policy providing access for developer")
      path                 = var.developer_policy == null ? var.default_path : lookup(var.developer_policy, "path", var.default_path)
      policy               = var.developer_policy == null ? data.aws_iam_policy_document.developer_from_external_accounts.json : lookup(var.developer_policy, "policy", data.aws_iam_policy_document.developer_from_external_accounts.json)
      service_principals   = var.developer_policy == null ? [] : lookup(var.developer_policy, "service_principals", [])
      aws_principals       = var.developer_policy == null ? var.developer_from_accounts : lookup(var.developer_policy, "aws_principals", [])
      federated_principals = var.developer_policy == null ? [] : lookup(var.developer_policy, "federated_principals", [])
      iam_policy_arns      = setunion(var.developer_policy == null ? [] : lookup(var.developer_policy, "iam_policy_arns", []), flatten(setproduct([/* flatten(setproduct()) is used to compose the set for use in the for_each */], [for policy in aws_iam_policy.developer_include_policies_copy : policy.arn])))
      role_requires_mfa    = var.developer_policy == null ? true : lookup(var.developer_policy, "role_requires_mfa", true)
    }
    self_manage = {
      /* The default use of var.aws_account_id in aws_principals looks weird but a role must have at least one principal. This role will typically not be used as the user exists in another account. */
      name                 = var.self_manage_policy == null ? "self-manage" : lookup(var.self_manage_policy, "name", "self-manage")
      description          = var.self_manage_policy == null ? "The policy providing access for managing ones own iam user" : lookup(var.self_manage_policy, "description", "The policy providing access for managing ones own iam user")
      path                 = var.self_manage_policy == null ? var.default_path : lookup(var.self_manage_policy, "path", var.default_path)
      policy               = var.self_manage_policy == null ? data.aws_iam_policy_document.iam_manage_self.json : lookup(var.self_manage_policy, "policy", data.aws_iam_policy_document.iam_manage_self.json)
      service_principals   = var.self_manage_policy == null ? [] : lookup(var.self_manage_policy, "service_principals", [])
      aws_principals       = var.self_manage_policy == null ? (length(var.self_manage_from_accounts) > 0 ? var.self_manage_from_accounts : [var.aws_account_id]) : lookup(var.support_from_external_accounts_policy, "aws_principals", [var.aws_account_id])
      federated_principals = var.self_manage_policy == null ? [] : lookup(var.self_manage_policy, "federated_principals", [])
      iam_policy_arns      = var.self_manage_policy == null ? [] : lookup(var.self_manage_policy, "iam_policy_arns", [])
      role_requires_mfa    = var.self_manage_policy == null ? true : lookup(var.self_manage_policy, "role_requires_mfa", true)
    }
    support_from_external_accounts = {
      /*
       * The default use of var.aws_account_id in aws_principals looks weird but a role must have at least one principal.
       * Policy: CIS AWS Web Services Foundations Benchmark
       * Control Name: Ensure a support role has been created to manage incidents with AWS Support
       * Criticality: HIGH
       * Without this role there may be a violation of the CIS Benchmark
       */
      name                 = var.support_from_external_accounts_policy == null ? "support" : lookup(var.support_from_external_accounts_policy, "name", "support")
      description          = var.support_from_external_accounts_policy == null ? "The policy providing access for managing ones own iam user and use AWS Support" : lookup(var.support_from_external_accounts_policy, "description", "The policy providing access for managing ones own iam user and use AWS Support")
      path                 = var.support_from_external_accounts_policy == null ? var.default_path : lookup(var.support_from_external_accounts_policy, "path", var.default_path)
      policy               = var.support_from_external_accounts_policy == null ? data.aws_iam_policy_document.require_mfa.json : lookup(var.support_from_external_accounts_policy, "policy", data.aws_iam_policy_document.require_mfa.json)
      service_principals   = var.support_from_external_accounts_policy == null ? [] : lookup(var.support_from_external_accounts_policy, "service_principals", [])
      aws_principals       = var.support_from_external_accounts_policy == null ? (length(var.support_from_accounts) > 0 ? var.support_from_accounts : [var.aws_account_id]) : lookup(var.support_from_external_accounts_policy, "aws_principals", [var.aws_account_id])
      federated_principals = var.support_from_external_accounts_policy == null ? [] : lookup(var.support_from_external_accounts_policy, "federated_principals", [])
      iam_policy_arns      = var.support_from_external_accounts_policy == null ? ["arn:aws:iam::aws:policy/AWSSupportAccess"] : lookup(var.support_from_external_accounts_policy, "iam_policy_arns", ["arn:aws:iam::aws:policy/AWSSupportAccess"])
      role_requires_mfa    = var.support_from_external_accounts_policy == null ? true : lookup(var.support_from_external_accounts_policy, "role_requires_mfa", true)
    }
    deny_all = {
      name                 = "deny-all"
      description          = "The policy providing access for denying all access"
      path                 = var.default_path
      policy               = data.aws_iam_policy_document.deny_all.json
      service_principals   = []
      aws_principals       = []
      federated_principals = []
      iam_policy_arns      = []
      role_requires_mfa    = true
    }
  }

  auto_deploy_service_principals = var.auto_deploy_service_principals

  developer_include_policies = var.developer_include_managed_policies
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE IAM POLICIES
# ----------------------------------------------------------------------------------------------------------------------

module "policy" {
  for_each = local.create_policies

  source = "../aws-iam-policy"

  name        = format("%s%s", var.policy_name_static_prefix, each.key)
  description = lookup(each.value, "description", "The policy providing access for ${each.value["name"]}")
  path        = lookup(each.value, "path", var.default_path)
  policy      = lookup(each.value, "policy", data.aws_iam_policy_document.deny_all.json)
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE IAM ROLES
# ----------------------------------------------------------------------------------------------------------------------

module "role" {
  for_each = local.policies

  source = "../aws-iam-role"

  name = replace(replace(format("%s%s", var.role_name_static_prefix, lookup(each.value, "name", each.key)), "_", "-"), "/[^\\w-]+/", "")

  path = lookup(each.value, "path", var.default_path)

  # list of aws services -- typically in the form of service_name.amazonaws.com
  service_principals = lookup(each.value, "service_principals", [])

  # convert a list of aws account id's into the iam principals
  aws_principals = [for principal in lookup(each.value, "aws_principals", []) : replace(principal, "/^\\d+$/", "") == "" ? "arn:aws:iam::${principal}:root" : principal]

  # oidc federation
  federated_principals = lookup(each.value, "federated_principals", [])

  # directly attached iam policies
  iam_policy_arns = lookup(each.value, "iam_policy_arns", [])

  require_mfa = lookup(each.value, "role_requires_mfa", true)

  tags = var.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# ATTACH POLICY TO ROLE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "policy" {
  for_each   = local.create_policies
  role       = module.role[each.key].id
  policy_arn = module.policy[each.key].arn
}


# ----------------------------------------------------------------------------------------------------------------------
# POLICIES - auto_deploy
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "auto_deploy_from_external_accounts" {
  statement {
    sid    = "AutoDeployPermissions"
    effect = "Allow"

    actions = var.auto_deploy_actions

    resources = ["*"]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# POLICIES - developer_from_external_accounts
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "developer_from_external_accounts" {
  statement {
    sid    = "DeveloperPermissions"
    effect = "Allow"

    actions = var.developer_actions

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy" "developer_include_policies" {
  for_each = contains(var.included_default_policy_names, "developer_from_external_accounts") ? local.developer_include_policies : []
  arn      = format("arn:aws:iam::aws:policy/%s", each.key)
}

resource "aws_iam_policy" "developer_include_policies_copy" {
  # CSPM will flag using policies that are directly managed by aws as they can change without warning
  # so we make a copy at the point in time that the roles are created.
  # these are dynamically included in local.default_policies.developer_from_external_accounts.iam_policy_arns
  for_each    = contains(var.included_default_policy_names, "developer_from_external_accounts") ? local.developer_include_policies : []
  name        = "${lookup(data.aws_iam_policy.developer_include_policies[each.key], "name", each.key)}Copy"
  description = "${lookup(data.aws_iam_policy.developer_include_policies[each.key], "description", each.key)} (Copy)"
  path        = var.default_path
  policy      = lookup(data.aws_iam_policy.developer_include_policies[each.key], "policy", {})
}

# ----------------------------------------------------------------------------------------------------------------------
# POLICIES - iam_manage_self
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "iam_manage_self" {
  statement {
    sid    = "SelfManagePermissions"
    effect = "Allow"

    actions = [
      "iam:ChangePassword",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:DeactivateMFADevice",
      "iam:DeleteAccessKey",
      "iam:DeleteLoginProfile",
      "iam:DeleteVirtualMFADevice",
      "iam:GenerateCredentialReport",
      "iam:GenerateServiceLastAccessedDetails",
      "iam:Get*",
      "iam:List*",
      "iam:ResyncMFADevice",
      "iam:UpdateAccessKey",
      "iam:UpdateLoginProfile",
      "iam:UpdateUser",
      "iam:UploadSigningCertificate",
    ]

    resources = [
      # aws uses a dynamic variable in the form of ${aws:variablename}
      # as terraform uses this syntax for interpolation we must escape that by writing it as $${aws:variablename}
      # https://www.terraform.io/docs/language/expressions/strings.html#escape-sequences-1
      "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}",
      "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  statement {
    # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_ssh-keys.html
    # For managing a set of credentials consisting of a user name and password that can be used to access the service specified in the request. These credentials are generated by IAM, and can be used only for the specified service.
    # You can have a maximum of two sets of service-specific credentials for each supported service per user.
    # The only supported service at this time is AWS CodeCommit.
    sid    = "SelfManageServiceSpecificCredentials"
    effect = "Allow"

    actions = [
      "iam:CreateServiceSpecificCredential",
      "iam:ListServiceSpecificCredentials",
      "iam:UpdateServiceSpecificCredential",
      "iam:DeleteServiceSpecificCredential",
      "iam:ResetServiceSpecificCredential",
    ]

    resources = [
      # aws uses a dynamic variable in the form of ${aws:variablename}
      # as terraform uses this syntax for interpolation we must escape that by writing it as $${aws:variablename}
      # https://www.terraform.io/docs/language/expressions/strings.html#escape-sequences-1
      "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  statement {
    sid    = "SelfManageSshKeys"
    effect = "Allow"

    actions = [
      "iam:DeleteSSHPublicKey",
      "iam:GetSSHPublicKey",
      "iam:ListSSHPublicKeys",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey",
    ]

    resources = [
      # aws uses a dynamic variable in the form of ${aws:variablename}
      # as terraform uses this syntax for interpolation we must escape that by writing it as $${aws:variablename}
      # https://www.terraform.io/docs/language/expressions/strings.html#escape-sequences-1
      "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  statement {
    sid    = "NoMFASelfManagePermissions"
    effect = "Allow"

    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
    ]

    resources = [
      # aws uses a dynamic variable in the form of ${aws:variablename}
      # as terraform uses this syntax for interpolation we must escape that by writing it as $${aws:variablename}
      # https://www.terraform.io/docs/language/expressions/strings.html#escape-sequences-1
      "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}",
      "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
    ]
  }

  statement {
    # this is required in order to get to the MFA page in the IAM console.
    sid    = "NoMFAReadMFAPermissions"
    effect = "Allow"

    actions = [
      "iam:ListUsers",
      "iam:ListVirtualMFADevices",
    ]

    resources = ["*"]
  }

  statement {
    # these are just nice to have
    sid    = "SelfSupportPermissions"
    effect = "Allow"

    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:GetGroupPolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetServiceLastAccessedDetails",
      "iam:ListAttachedGroupPolicies",
      "iam:ListEntitiesForPolicy",
      "iam:ListGroupPolicies",
      "iam:ListGroups",
      "iam:ListPolicyVersions",
    ]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  statement {
    # The iam:ListUsers operation does not have the ability to filter the results. All users or no users will be visible.
    sid    = "listAllIamUsers"
    effect = "Allow"

    actions = [
      "iam:ListUsers",
    ]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# POLICIES - require_mfa
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "require_mfa" {

  # Sourced from https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage-mfa-only.html
  statement {
    sid       = "AllowViewAccountInfo"
    effect    = "Allow"
    actions   = ["iam:ListVirtualMFADevices"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageOwnVirtualMFADevice"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice"
    ]

    resources = [
      "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}",
    ]
  }

  statement {
    sid    = "AllowManageOwnUserMFA"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
      # The mfa/${aws:username} resource is not included in the documentation
      # but is required for the user to perform some of the iam:*MFA* actions
      "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}",
    ]
  }

  statement {
    sid    = "DenyAllExceptListedIfNoMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# POLICIES - deny_all
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "deny_all" {
  statement {
    sid    = "DenyAll"
    effect = "Deny"
    actions = [
      "*"
    ]
    resources = ["*"]
  }
}
