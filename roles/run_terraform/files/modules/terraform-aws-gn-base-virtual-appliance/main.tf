module "base_virtual_appliance" {
  source  = "app.terraform.io/marriott/terraform-aws-gn-base-virtual-appliance/aws"
  version = "1.0.7"

  providers = { aws = aws.provider_alias }

  vpc_id          = var.vpc_id
  ami_id          = var.ami_id
  instance_type   = var.instance_type
  enis            = var.enis
  create_key_pair = var.create_key_pair
  key_name        = var.key_name
  public_key      = var.public_key

  # TAGS
  name          = var.name
  dud           = var.dud
  department    = var.department
  environment   = var.environment
  accenture_ru  = var.accenture_ru
  owner         = var.owner
  domain        = var.domain
  createdby     = var.createdby
  project       = var.project
  cloudservice  = var.cloudservice
  location      = var.location
  nonGamiEc2    = var.nonGamiEc2
}

resource "aws_key_pair" "main" {
  count = length(data.aws_key_pair.existing_key_pair.id) == 0 ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key
}

data "aws_key_pair" "existing_key_pair" {
  key_name = var.key_name
}

resource "aws_security_group" "main" {
  count = length(data.aws_security_group.existing_sg.id) == 0 ? 1 : 0
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
    protocol    = "-1"
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

resource "aws_instance" "main" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.main[0].id
    device_index         = 0
  }

  vpc_security_group_ids = [aws_security_group.main[0].id]

  tags = local.tags
}

resource "aws_network_interface_attachment" "main" {
  count = length(var.enis)
  instance_id          = aws_instance.main.id
  network_interface_id = aws_network_interface.main[count.index].id
  device_index         = count.index
}