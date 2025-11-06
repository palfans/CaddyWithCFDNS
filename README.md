# Caddy with Cloudflare DNS

Custom Caddy server with Cloudflare DNS plugin for automatic HTTPS.

## Build

```bash
# Local build (current platform)
./build.sh local

# Multi-platform build and push to registry
./build.sh push

# Custom version
./build.sh local 2.9.0
```

Binaries are extracted to `release/` directory.

## Usage

```bash
docker run -d \
  -p 80:80 -p 443:443 \
  -e CLOUDFLARE_API_TOKEN=your_token \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data \
  palfans/caddy:latest
```

Example Caddyfile:

```caddyfile
example.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy localhost:8080
}
```
