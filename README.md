# CNS Ansible AWS Infrastructure Management

This Ansible project provides automated management of AWS EC2 instances across multiple regions and accounts using Terraform Cloud as the backend.

## Overview

This project enables:
- Creation and management of EC2 instances across multiple AWS regions and accounts
- Security group and ENI management
- SSH key pair generation and management
- Instance verification and command execution
- Automated instance termination based on configuration

## Requirements

- Ansible 2.9+
- Python 3.6+
- AWS CLI configured
- Required Collections:
  ```yaml
  collections:
    - community.aws
    - amazon.aws
    - community.general
    - awx.awx
    - ansible.utils
    - community.crypto
  ```

## Project Structure

```
.
├── collections/
│   └── requirements.yml
├── plugins/
│   └── lookup/
│       └── instance_iterator.py
└── roles/
    ├── assume_role/
    └── run_terraform/
```

## Core Components

### Instance Iterator Plugin
The `instance_iterator.py` provides instance data processing:

```python
def run(self, terms, variables=None, **kwargs):
    instances = terms[0]
    formatted_instances = []

    for instance in instances:
        formatted_instance = {
            'region': instance.get('aws_region'),
            'vpc_id': instance.get('vpc_id'),
            'type': instance.get('instance_type'),
            'account': instance.get('aws_account_id'),
            'name': instance.get('name'),
            'key': instance.get('key_name'),
            'command': instance.get('command_to_run'),
            'ami_id': instance.get('ami_id'),
            'terminate_instance': instance.get('terminate_instance', False),
            'enis': []
        }
        formatted_instances.append(formatted_instance)

    return formatted_instances
```

### Key Roles

#### roles/assume_role:
- Handles AWS role assumption for cross-account access
- Manages AWS credentials

#### roles/run_terraform:
- Manages Terraform configurations
- Handles EC2 instance lifecycle
- Processes security groups and ENIs
- Manages SSH key pairs
- Executes instance verification

## Usage

```hcl
module "base_virtual_appliance" {
  source  = "app.terraform.io//terraform-aws-gn-base-virtual-appliance/aws"
  version = "1.0.0"

  vpc_id        = "vpc-xxxxx"
  ami_id        = "ami-xxxxx"
  instance_type = "t2.small"

  enis = [{
    subnet_id     = "subnet-xxxxx"
    associate_eip = true
    name          = "terraform-aws-gn-base-virtual-appliance-eni"
    inbound_rules = [{
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["10.0.0.0/8"]
    }]
  }]

  # Required Tags
  name          = "my-appliance"
  dud           = "12345678901"
  department    = "IT"
  environment   = "dev"
  accenture_ru  = "n"
  owner         = "team-name"
  domain        = "domain-name"
  createdby     = "terraform"
  project       = "project-name"
  cloudservice  = "no_tier0_ec2"
  location      = "aws-us-east-1"
}
```

### Ansible Automation Platform Extra Vars Payload

```yaml
---
# Infrastructure Configuration
vpc_id: "vpc-xxxxx"
ami_id: "ami-xxxxx"
instance_type: "t2.micro"

# Network Configuration
enis:
  - subnet_id: "subnet-xxxxx"
    security_groups:
      - "sg-xxxxx"

# Instance Configuration
metadata_options:
  http_tokens: required

# Required Tags
environment: "dev"
project: "project-name"
owner: "team-name"
createdby: "terraform"
cloudservice: "no_tier0_ec2"
location: "aws-us-east-1"
dud: "12345678901"
name: "my-appliance"
department: "non_prod"  # or prod
accenture_ru: "n"
domain: "domain-name"
nonGamiEc2: ""
```
