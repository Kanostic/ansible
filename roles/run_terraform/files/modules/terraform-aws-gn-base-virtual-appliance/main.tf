module "base_virtual_appliance" {
  source  = "app.terraform.io/marriott/terraform-aws-gn-base-virtual-appliance/aws"
  version = "1.0.14"

  providers = { aws = aws.provider_alias }

  vpc_id          = var.vpc_id
  ami_id          = var.ami_id
  instance_type   = var.instance_type
  enis            = var.enis
  create_key_pair = var.create_key_pair
  key_name        = var.key_name
  public_key      = var.public_key != "" ? var.public_key : tls_private_key.main[0].public_key_openssh
  root_volume_size = var.root_volume_size
  tags             = var.tags
}

resource "tls_private_key" "main" {
  count     = var.public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  count     = length(data.aws_key_pair.existing_key_pair.id) == 0 ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key != "" ? var.public_key : tls_private_key.main[0].public_key_openssh
}

data "aws_key_pair" "existing_key_pair" {
  key_name = var.key_name
}

resource "aws_security_group" "main" {
  count     = length(data.aws_security_group.existing_sg.id) == 0 ? 1 : 0
  name        = var.name
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = [var.name]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Move network interfaces before the instance
resource "aws_network_interface" "main" {
  count     = length(var.enis)
  subnet_id = var.enis[count.index].subnet_id

  security_groups = length(var.enis[count.index].security_groups) > 0 ? var.enis[count.index].security_groups : [
    length(aws_security_group.main) > 0 ? aws_security_group.main[0].id : data.aws_security_group.existing_sg.id
  ]

  private_ips       = lookup(var.enis[count.index], "private_ips", null)
  source_dest_check = lookup(var.enis[count.index], "source_dest_check", true)

  tags = merge(local.tags, {
    Name = var.enis[count.index].name != null ? var.enis[count.index].name : "${var.name}-eni-${count.index + 1}"
  })
}

resource "aws_instance" "main" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile = var.enable_s3_upload_role && var.s3_bucket_name != "" ? aws_iam_instance_profile.s3_upload[0].name : null

  # Attach primary ENI if var.enis is not empty
  dynamic "network_interface" {
    for_each = var.enis
    content {
      network_interface_id = aws_network_interface.main[index].id
      device_index         = 0
    }
  }

  # Use security groups directly when no ENIs are defined
  vpc_security_group_ids = length(var.enis) == 0 ? [
    length(aws_security_group.main) > 0 ? aws_security_group.main[0].id : data.aws_security_group.existing_sg.id
  ] : null

  # Use subnet_id when no ENIs are defined
  subnet_id = length(var.enis) == 0 ? var.vpc_id : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = var.metadata_options.http_tokens
  }

  tags = local.tags
}

# Attach additional ENIs (skip index 0 since it's attached in the instance)
resource "aws_network_interface_attachment" "main" {
  count                = length(var.enis) > 1 ? length(var.enis) - 1 : 0
  instance_id          = aws_instance.main.id
  network_interface_id = aws_network_interface.main[count.index + 1].id
  device_index         = count.index + 1
}