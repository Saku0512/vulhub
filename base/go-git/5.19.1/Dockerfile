FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod ./
COPY main.go ./
RUN go mod tidy \
    && CGO_ENABLED=0 go build -o /out/poc .

FROM alpine:3.23

LABEL maintainer="phithon <root@leavesongs.com>"

COPY --from=builder /out/poc /usr/local/bin/poc

CMD ["sleep", "infinity"]
