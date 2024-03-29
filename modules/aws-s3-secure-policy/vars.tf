variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for buckets in this account. Defaults to true."
  default     = true
  type        = bool
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for buckets in this account. Defaults to true."
  default     = true
  type        = bool
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for buckets in this account. Defaults to true."
  default     = true
  type        = bool
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for buckets in this account. Defaults to true."
  default     = true
  type        = bool
}
