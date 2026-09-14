FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl gettext-base && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/start_nginx.sh /usr/local/bin/start_nginx.sh
RUN chmod +x /usr/local/bin/start_nginx.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/start_nginx.sh"]
