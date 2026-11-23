FROM httpd:latest

# Metadatos contenedores
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

COPY index.html /usr/local/apache2/htdocs/index.html
COPY ecs-entrypoint.sh /usr/local/bin/ecs-entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/ecs-entrypoint.sh \
    && chmod +x /usr/local/bin/ecs-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/ecs-entrypoint.sh"]
CMD ["httpd-foreground"]
