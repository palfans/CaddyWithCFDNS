FROM arm64v8/caddy:builder-alpine AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM arm64v8/caddy:alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy