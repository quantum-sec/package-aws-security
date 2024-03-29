variable "max_password_age" {
  description = "The number of days that an user password is valid."
  default     = 90
  type        = number
}

variable "minimum_password_length" {
  description = "Minimum length to require for user passwords."
  default     = 14
  type        = number
}

variable "password_reuse_prevention" {
  description = "The number of previous passwords that users are prevented from reusing."
  default     = 24
  type        = number
}

variable "require_lowercase_characters" {
  description = "Whether to require lowercase characters for user passwords."
  default     = true
  type        = bool
}

variable "require_numbers" {
  description = "Whether to require numbers for user passwords."
  default     = true
  type        = bool
}

variable "require_uppercase_characters" {
  description = "Whether to require uppercase characters for user passwords."
  default     = true
  type        = bool
}

variable "require_symbols" {
  description = "Whether to require symbols for user passwords."
  default     = true
  type        = bool
}

variable "allow_users_to_change_password" {
  description = "Whether to allow users to change their own password."
  default     = true
  type        = bool
}

variable "create_password_policy" {
  type        = bool
  description = "Define if the password policy should be created."
  default     = true
}
