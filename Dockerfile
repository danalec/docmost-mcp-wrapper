# Build stage: compile the upstream TypeScript source
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# Runtime stage
FROM node:22-alpine

# Install Python and mcp-proxy (Python package for stdio-to-HTTP bridging)

# Create non-root user

WORKDIR /app

# Production dependencies only (no devDependencies like typescript)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy compiled output from builder
COPY --from=builder /app/build ./build

# Copy entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8088

# Non-root user. If the Tailscale hook requires root, override with:
#   --user root --cap-add=NET_ADMIN --cap-add=NET_RAW
USER node

ENTRYPOINT ["/docker-entrypoint.sh"]
