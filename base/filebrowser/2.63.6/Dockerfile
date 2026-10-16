FROM filebrowser/filebrowser:v2.63.6@sha256:738e984198074d25e0134ace6a8ba63537ff44b4f48bcc8421935a8dc8082492

LABEL maintainer="phithon <root@leavesongs.com>"

COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

ENV FB_ADDRESS=127.0.0.1 \
    FB_PORT=80

ENTRYPOINT ["/bin/tini", "--", "/docker-entrypoint.sh"]
