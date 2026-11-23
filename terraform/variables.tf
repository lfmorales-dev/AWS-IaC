variable "aws_region" {
  description = "Región de AWS donde se crea todo"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "nombre del proyecto"
  type        = string
  default     = "parcial-ecs"
}

variable "vpc_name" {
  description = "Etiqueta Name de la VPC donde se despliega todo"
  type        = string
  default     = "VPCEterno"
}

variable "public_subnet_name_pattern" {
  description = "Patron del Name de las subnets publicas (admite *)"
  type        = string
  default     = "*public*"
}

variable "github_repo" {
  description = "Repositorio"
  type        = string
  default     = "Susana2306/Final_AWS"
}

variable "github_branch" {
  description = "Rama que dispara el pipeline"
  type        = string
  default     = "main"
}

variable "codeconnection_arn" {
  description = "ARN de una conexión de CodeConnections"
  type        = string
  default     = "arn:aws:codeconnections:us-east-1:808644003384:connection/e29b8190-c05e-4622-89cf-f4c19e46f038"
}

variable "container_name" {
  description = "Contenedor"
  type        = string
  default     = "app"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "task_cpu" {
  description = "CPU reservada por tarea 0.25 vCPU"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memoria reservada por tarea en MiB"
  type        = number
  default     = 512
}

variable "build_initial_image" {
  description = "Imagen inicial"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "t3.small con modo de red bridge"
  type        = string
  default     = "t3.small"
}

variable "instance_count" {
  description = "Número fijo de instancias EC2 del clúster (sin autoscaling)"
  type        = number
  default     = 2
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "cpu_target" {
  description = "Porcentaje de CPU para escalar"
  type        = number
  default     = 10
}

variable "domain_name" {
  description = "Dominio externo que apunta al ALB"
  type        = string
  default     = "www.lfmcsss.space"
}
