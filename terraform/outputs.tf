output "alb_dns_name" {
  description = "CNAME para dominio"
  value       = aws_lb.main.dns_name
}

output "url_alb" {
  value = "http://${aws_lb.main.dns_name}"
}

output "url_dominio" {
  value = var.domain_name == "" ? "(configura domain_name)" : "http://${var.domain_name}"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service" {
  value = aws_ecs_service.app.name
}

output "pipeline_name" {
  value = aws_codepipeline.app.name
}

output "codeconnection_arn" {
  description = "Guárdalo en terraform.tfvars (codeconnection_arn) después de activarla"
  value       = local.connection_arn
}

output "siguiente_paso" {
  value = var.codeconnection_arn == "" ? "Activa la conexion en: Consola > Developer Tools > Settings > Connections > ${substr("${local.name}-github", 0, 32)} > Update pending connection" : "Conexion existente en uso. Haz push o 'Release change' en el pipeline."
}
