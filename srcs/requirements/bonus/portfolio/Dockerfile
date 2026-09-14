FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY site/ /var/www/portfolio/

EXPOSE 8081

ENTRYPOINT ["nginx", "-g", "daemon off;"]
