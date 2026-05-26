variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the instance"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The type of the instance"
  type        = string
  default     = ""
}

variable "enis" {
  description = "List of ENIs with subnet_id and other properties"
  type = list(object({
    subnet_id     = string
    name          = optional(string)
    associate_eip = optional(bool, false)
    inbound_rules = optional(list(object({
      protocol        = string
      from_port       = number
      to_port         = number
      cidr_blocks     = optional(list(string), [])
      prefix_list_ids = optional(list(string), [])
      description     = optional(string)
    })), [])
    security_groups = optional(list(string), [])
  }))
}

variable "environment" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
}

variable "project" {
  description = "Project tag"
  type        = string
}

variable "owner" {
  description = "Owner tag"
  type        = string
}

variable "createdby" {
  description = "Created by tag"
  type        = string
}

variable "cloudservice" {
  description = "Cloud service tag"
  type        = string
  default     = "no_tier0_ec2"
}

variable "location" {
  description = "Location tag"
  type        = string
  default     = ""
}

variable "dud" {
  description = "DUD tag"
  type        = string
}

variable "name" {
  description = "Name tag for the resource"
  type        = string
}

variable "department" {
  description = "Department tag"
  type        = string
  default     = ""
}

variable "accenture_ru" {
  description = "Accenture RU tag"
  type        = string
  default     = "n"
}

variable "domain" {
  description = "Domain tag"
  type        = string
  default     = ""
}

variable "nonGamiEc2" {
  description = "Non-GAMI EC2 tag"
  type        = string
  default     = null
}

variable "metadata_options" {
  description = "Configuration for metadata options (IMDSv2)"
  type = object({
    http_tokens = string
  })
  default = {
    http_tokens = "optional"
  }
}

variable "public_key" {
  description = "The public key to be used for the key pair. If not provided, a new key pair will be generated."
  type        = string
  default     = ""
}

variable "create_key_pair" {
  description = "Whether to create a key pair"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
}

variable "root_volume_size" {
    description ="The size of the root volume"
    type      = number
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources"
  default     = {}
}

# IAM/S3 upload settings
variable "enable_s3_upload_role" {
  description = "Whether to create and attach an IAM role/instance profile that allows this instance to upload artifacts to S3"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name where the instance will upload results (e.g., mi-cns-orgshared-bucket-38asdh2)"
  type        = string
  default     = ""
}

variable "s3_bucket_prefix" {
  description = "Target S3 key prefix within the bucket (e.g., connectivity_results/). A trailing slash is recommended."
  type        = string
  default     = "connectivity_results/"
}

variable "s3_allow_list_bucket" {
  description = "If true, also allow ListBucket scoped to the configured prefix. Some aws s3 CLI operations may require this."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN used for SSE-KMS when uploading to S3. If provided, kms permissions will be granted."
  type        = string
  default     = null
}