FROM node:22-alpine

LABEL maintainer="phithon <root@leavesongs.com>"

WORKDIR /app

RUN corepack enable \
    && corepack prepare pnpm@10.17.1 --activate \
    && pnpm init \
    && pnpm add --save-exact nuxt@4.5.0

COPY app.vue nuxt.config.ts ./

EXPOSE 3000

CMD ["npx", "nuxt", "dev", "--host", "0.0.0.0", "--port", "3000"]

