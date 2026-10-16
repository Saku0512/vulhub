FROM docker:28.0.1-dind

LABEL maintainer="phithon <root@leavesongs.com>"

ARG KIND_VERSION=v0.30.0
ARG KUBECTL_VERSION=v1.32.2
ARG TARGETARCH

RUN apk add --no-cache bash curl \
    && curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${TARGETARCH}" \
        -o /usr/local/bin/kind \
    && curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
        -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kind /usr/local/bin/kubectl

COPY kind-config.yaml traefik-v371.yaml gateway-exploit.yaml /opt/poc/
COPY run-poc.sh /usr/local/bin/run-poc

