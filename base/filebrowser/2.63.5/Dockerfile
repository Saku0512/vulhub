FROM filebrowser/filebrowser:v2.63.5

LABEL maintainer="phithon <root@leavesongs.com>"

COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

ENV FB_ADDRESS=127.0.0.1 \
    FB_PORT=80

ENTRYPOINT ["/bin/tini", "--", "/docker-entrypoint.sh"]
