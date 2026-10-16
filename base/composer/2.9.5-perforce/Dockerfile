FROM composer:2.9.5 AS composer

FROM php:8.3-cli-bookworm

LABEL maintainer="phithon <root@leavesongs.com>"

ARG P4_RELEASE=r25.2
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) p4_arch='x86_64' ;; \
        arm64) p4_arch='aarch64' ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    p4_base="https://ftp.perforce.com/pub/perforce/${P4_RELEASE}/bin.linux26${p4_arch}"; \
    curl --fail --location --silent --show-error "${p4_base}/p4" --output /usr/local/bin/p4; \
    curl --fail --location --silent --show-error "${p4_base}/SHA256SUMS" --output /tmp/SHA256SUMS; \
    expected_sum="$(awk '$2 == "*p4" { print $1; exit }' /tmp/SHA256SUMS)"; \
    test -n "${expected_sum}"; \
    echo "${expected_sum}  /usr/local/bin/p4" | sha256sum --check --strict; \
    chmod 0755 /usr/local/bin/p4; \
    rm /tmp/SHA256SUMS

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY --chmod=755 run-poc.sh /usr/local/bin/run-poc
COPY composer.json /opt/poc/composer.json

RUN useradd --create-home --shell /usr/sbin/nologin poc \
    && mkdir /work \
    && chown poc:poc /work

USER poc
WORKDIR /work

CMD ["sleep", "infinity"]

