FROM caddy:builder-alpine AS builder
ENV GOPROXY=direct
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy