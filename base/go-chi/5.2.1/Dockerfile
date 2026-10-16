FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
RUN CGO_ENABLED=0 go build -o /server .

FROM alpine:3.21

LABEL maintainer="phithon <root@leavesongs.com>"

COPY --from=builder /server /usr/local/bin/server

EXPOSE 8080

CMD ["server"]

