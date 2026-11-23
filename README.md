# Parcial AWS: ECS sobre EC2 (bridge) + ALB + Auto Scaling + CodePipeline (Terraform)

```
app/                      -> Dockerfile (Apache httpd), index.html (presentación) y ecs-entrypoint.sh
buildspec.yml             -> instrucciones de CodeBuild (build, push a ECR, imagedefinitions.json)
terraform/                -> toda la infraestructura
```

## Despliegue rápido

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edita github_repo
terraform init
terraform apply
```

1. Activa la conexión de GitHub (output `siguiente_paso`) si es nueva.
2. Crea un CNAME en tu dominio hacia el output `alb_dns_name`.
3. En CodePipeline: **Release change** (o haz un push), aprueba la etapa manual.

## Prueba del pipeline

Cambia `<span class="version-tag">v1</span>` por `v2` en `app/index.html`, luego:

```bash
git add . && git commit -m "v2" && git push
```

## Borrar todo

```bash
terraform destroy
```
