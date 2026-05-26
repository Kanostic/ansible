locals {
  tags = {
    name          = var.name
    environment   = lower(var.environment)
    project       = var.project
    owner         = var.owner
    createdby     = var.createdby
    cloudservice  = var.cloudservice
    location      = var.location
    dud           = var.dud
    department    = var.department
    accenture_ru  = var.accenture_ru
    domain        = var.domain
    nonGamiEc2    = var.nonGamiEc2
  }
}