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

# VPC propia, buscada por su etiqueta Name (var.vpc_name)
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Subnets públicas de la VPC (Name contiene "public"), una por cada AZ de local.azs
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_name_pattern]
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
