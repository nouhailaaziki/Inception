FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends php-cli php-mysqli curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/www/adminer && \
    curl -sSL -o /var/www/adminer/index.php \
        https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

WORKDIR /var/www/adminer

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]
