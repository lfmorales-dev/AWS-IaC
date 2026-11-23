terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Proyecto = var.project_name
      Gestion  = "terraform"
      Contexto = "parcial-aws"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC por defecto de la cuenta (ya trae Internet Gateway y subnets públicas)
data "aws_vpc" "default" {
  default = true
}

# Subnets por defecto de la VPC, una por cada AZ de local.azs
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "availability-zone"
    values = local.azs
  }
}

locals {
  name         = var.project_name
  account_id   = data.aws_caller_identity.current.account_id
  ecr_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
}
