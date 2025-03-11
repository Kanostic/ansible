locals {
  tags = {
    Name          = var.name
    Environment   = var.environment
    Project       = var.project
    Owner         = var.owner
    CreatedBy     = var.createdby
    CloudService  = var.cloudservice
    Location      = var.location
    DUD           = var.dud
    Department    = var.department
    AccentureRU   = var.accenture_ru
    Domain        = var.domain
    NonGamiEC2    = var.nonGamiEc2
  }
}