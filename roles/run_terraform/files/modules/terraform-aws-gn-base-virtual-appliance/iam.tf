#########################
# IAM role for S3 upload #
#########################

locals {
	_s3_prefix_no_leading = trim(var.s3_bucket_prefix, "/")
	s3_object_arn_prefix  = var.s3_bucket_name == "" ? null : "arn:aws:s3:::${var.s3_bucket_name}/${local._s3_prefix_no_leading}*"
	s3_bucket_arn         = var.s3_bucket_name == "" ? null : "arn:aws:s3:::${var.s3_bucket_name}"
}

resource "aws_iam_role" "s3_upload" {
	count = var.enable_s3_upload_role && var.s3_bucket_name != "" ? 1 : 0

	name               = "${var.name}-s3-upload-role"
	assume_role_policy = jsonencode({
		Version = "2012-10-17",
		Statement = [{
			Effect = "Allow",
			Principal = { Service = "ec2.amazonaws.com" },
			Action = "sts:AssumeRole"
		}]
	})

		tags = merge(local.tags, {
			environment = lower(var.environment)
		})
}

data "aws_iam_policy_document" "s3_write" {
	count = var.enable_s3_upload_role && var.s3_bucket_name != "" ? 1 : 0

	statement {
		sid    = "PutObjectsWithKms"
		effect = "Allow"
		actions = [
			"s3:PutObject",
			"s3:PutObjectAcl",
			"s3:AbortMultipartUpload",
			"s3:ListBucketMultipartUploads",
			"s3:ListMultipartUploadParts"
		]
		resources = [local.s3_object_arn_prefix]
		condition {
			test     = "StringEqualsIfExists"
			variable = "s3:x-amz-server-side-encryption"
			values   = ["aws:kms", "AES256"]
		}
	}

	dynamic "statement" {
		for_each = var.s3_allow_list_bucket ? [1] : []
		content {
			sid    = "ListBucketForPrefix"
			effect = "Allow"
			actions = [
				"s3:ListBucket"
			]
			resources = [local.s3_bucket_arn]
			condition {
				test     = "StringLike"
				variable = "s3:prefix"
				values   = ["${local._s3_prefix_no_leading}*"]
			}
		}
	}

	dynamic "statement" {
		for_each = var.kms_key_arn != null && var.kms_key_arn != "" ? [1] : []
		content {
			sid    = "KmsEncryptDecrypt"
			effect = "Allow"
			actions = [
				"kms:Encrypt",
				"kms:Decrypt",
				"kms:GenerateDataKey*",
				"kms:DescribeKey"
			]
			resources = [var.kms_key_arn]
		}
	}
}

resource "aws_iam_policy" "s3_write" {
	count       = var.enable_s3_upload_role && var.s3_bucket_name != "" ? 1 : 0
	name        = "${var.name}-s3-upload-policy"
	description = "Allow instance to upload connectivity results to S3"
	policy      = data.aws_iam_policy_document.s3_write[0].json
	tags        = merge(local.tags, {
		environment = lower(var.environment)
	})
}

resource "aws_iam_role_policy_attachment" "attach" {
	count      = var.enable_s3_upload_role && var.s3_bucket_name != "" ? 1 : 0
	role       = aws_iam_role.s3_upload[0].name
	policy_arn = aws_iam_policy.s3_write[0].arn
}

resource "aws_iam_instance_profile" "s3_upload" {
	count = var.enable_s3_upload_role && var.s3_bucket_name != "" ? 1 : 0
	name  = "${var.name}-s3-upload-profile"
	role  = aws_iam_role.s3_upload[0].name
	tags  = merge(local.tags, {
		environment = lower(var.environment)
	})
}
