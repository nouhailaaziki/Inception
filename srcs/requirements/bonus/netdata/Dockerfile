FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        netdata && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/' /etc/netdata/netdata.conf

COPY tools.sh /usr/local/bin/tools.sh
RUN chmod +x /usr/local/bin/tools.sh

RUN printf '%s\n' \
    '[plugin:cgroups]' \
    '    path to /sys/fs/cgroup = /host/sys/fs/cgroup' \
    >> /etc/netdata/netdata.conf

EXPOSE 19999

ENTRYPOINT ["/usr/local/bin/tools.sh"]
