FROM node:22-alpine@sha256:0a7108bf6c7bf5de370ffb1a3ed6be93d405b43ff159f681a8d18c0e2bc2e402

LABEL maintainer="phithon <root@leavesongs.com>"

WORKDIR /app

RUN corepack enable \
    && corepack prepare pnpm@10.17.1 --activate \
    && pnpm init \
    && pnpm add --save-exact nuxt@4.5.0

COPY app.vue nuxt.config.ts ./

EXPOSE 80

CMD ["npx", "nuxt", "dev", "--host", "0.0.0.0", "--port", "80"]

