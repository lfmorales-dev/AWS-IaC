#!/bin/sh
# Punto de entrada del contenedor. Se ejecuta antes de arrancar Apache:
#  - ID de la tarea: endpoint de metadatos de ECS v4 (TaskARN)
#  - Zona de disponibilidad e ID de instancia: metadatos de la instancia EC2 (IMDSv2)
# Reemplaza __TASK_ID__, __TASK_SHORT__, __AZ__, __INSTANCE_ID__ y __APP_VERSION__
# en index.html y luego ejecuta el comando original de la imagen (httpd-foreground).

HTML="${HTML_FILE:-/usr/local/apache2/htdocs/index.html}"
TASK_ID="local (fuera de ECS)"
AZ="local (fuera de ECS)"
INSTANCE_ID="local (fuera de ECS)"
AZ_META=""

if [ -n "$ECS_CONTAINER_METADATA_URI_V4" ]; then
  # 1) Metadatos de la tarea ECS
  META=$(curl -s -m 3 "$ECS_CONTAINER_METADATA_URI_V4/task" || true)
  if [ -n "$META" ]; then
    TASK_ARN=$(echo "$META" | jq -r '.TaskARN // empty' 2>/dev/null)
    [ -n "$TASK_ARN" ] && TASK_ID="${TASK_ARN##*/}"
    AZ_META=$(echo "$META" | jq -r '.AvailabilityZone // empty' 2>/dev/null)
  fi

  # 2) Metadatos de la instancia EC2 donde corre la tarea (IMDSv2)
  TOKEN=$(curl -s -m 3 -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || true)
  if [ -n "$TOKEN" ]; then
    IID=$(curl -s -m 3 -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id || true)
    echo "$IID" | grep -Eq '^i-[0-9a-f]+$' && INSTANCE_ID="$IID"
    if [ -z "$AZ_META" ]; then
      AZ_META=$(curl -s -m 3 -H "X-aws-ec2-metadata-token: $TOKEN" \
        http://169.254.169.254/latest/meta-data/placement/availability-zone || true)
    fi
  fi

  echo "$AZ_META" | grep -Eq '^[a-z]{2}(-[a-z]+)+-[0-9][a-z]$' && AZ="$AZ_META"
fi

TASK_SHORT=$(echo "$TASK_ID" | cut -c 1-8)

sed -i \
  -e "s|__TASK_ID__|${TASK_ID}|g" \
  -e "s|__TASK_SHORT__|${TASK_SHORT}|g" \
  -e "s|__AZ__|${AZ}|g" \
  -e "s|__INSTANCE_ID__|${INSTANCE_ID}|g" \
  -e "s|__APP_VERSION__|${APP_VERSION:-dev}|g" \
  "$HTML"

echo "[ecs-metadata] Tarea: ${TASK_ID} | AZ: ${AZ} | Instancia: ${INSTANCE_ID} | Imagen: ${APP_VERSION:-dev}"

# Arranca Apache (o el comando que se pase al contenedor)
exec "$@"
