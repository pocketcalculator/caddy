# Advanced Caddy build with Cloudflare DNS plugin using official builder/runtime

# Stage 1: Use official Caddy builder (pins compatible Go toolchain and flags)
FROM caddy:2-builder-alpine AS builder

# Build Caddy with Cloudflare DNS plugin
# Build latest Caddy with Cloudflare DNS plugin
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

# Stage 2: Use official lightweight runtime
FROM caddy:2-alpine

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Copy custom configuration file
COPY Caddyfile /etc/caddy/Caddyfile

# Copy any additional static files (optional)
COPY html/ /usr/share/caddy/

# Set working directory
WORKDIR /usr/share/caddy

# Expose ports
EXPOSE 80 443 2019

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD caddy version && caddy validate --config /etc/caddy/Caddyfile || exit 1

# Use environment variables for configuration
ENV CADDY_ADMIN=0.0.0.0:2019

# Run Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
