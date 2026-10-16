FROM golang:1.25-alpine@sha256:1ae0735f00daffa3aaf1363a5184c0d2dc55c78e3db4ec70241cdac97bf84b59 AS builder

WORKDIR /src

COPY go.mod ./
COPY main.go ./
RUN go mod tidy \
    && CGO_ENABLED=0 go build -o /out/poc .

FROM alpine:3.23@sha256:85fe1e81d6758c208f3e1eed4338a1997e19d4be002d4dd32d3100c9a8c010a0

LABEL maintainer="phithon <root@leavesongs.com>"

COPY --from=builder /out/poc /usr/local/bin/poc

CMD ["sleep", "infinity"]
