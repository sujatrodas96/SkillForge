variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name"
}

variable "versioning_enabled" {
  type        = bool
  default     = true
  description = "Keep old object versions (recommended for Terraform state)"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 90
  description = "Days after which noncurrent object versions are deleted"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow Terraform to delete the bucket even if it contains objects"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the bucket"
}