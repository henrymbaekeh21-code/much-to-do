# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./
RUN go mod download

COPY Server/MuchToDo/ .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/api

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM alpine:3.19

RUN apk --no-cache add ca-certificates wget tzdata && \
    addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/server .

# Startup script that writes .env from environment variables
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo "PORT=${PORT:-8080}" > /app/.env' >> /app/start.sh && \
    echo 'echo "MONGO_URI=${MONGO_URI}" >> /app/.env' >> /app/start.sh && \
    echo 'echo "DB_NAME=${DB_NAME:-muchtodo}" >> /app/.env' >> /app/start.sh && \
    echo 'echo "JWT_SECRET_KEY=${JWT_SECRET_KEY}" >> /app/.env' >> /app/start.sh && \
    echo 'echo "JWT_EXPIRATION_HOURS=${JWT_EXPIRATION_HOURS:-72}" >> /app/.env' >> /app/start.sh && \
    echo 'echo "ENABLE_CACHE=${ENABLE_CACHE:-false}" >> /app/.env' >> /app/start.sh && \
    echo 'echo "LOG_LEVEL=${LOG_LEVEL:-info}" >> /app/.env' >> /app/start.sh && \
    echo 'echo "LOG_FORMAT=${LOG_FORMAT:-text}" >> /app/.env' >> /app/start.sh && \
    echo 'exec ./server' >> /app/start.sh && \
    chmod +x /app/start.sh

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/start.sh"]