# Stage 1: Build the Linux AMD64 binary
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Copy go.mod/go.sum and download deps (cacheable)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the code
COPY . .

# Build a static Linux/amd64 binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags "-s -w" \
    -o /bin/github-mcp-server \
    cmd/github-mcp-server/main.go

# Stage 2: Run via Supergateway
FROM ghcr.io/supercorp-ai/supergateway:v2.4.0

# Copy the binary in and make executable
COPY --from=builder /bin/github-mcp-server /usr/bin/github-mcp-server
RUN chmod +x /usr/bin/github-mcp-server

# Supergateway entrypoint
ENTRYPOINT ["supergateway"]
CMD ["--stdio", "/usr/bin/github-mcp-server stdio", "--port", "8080", "--ssePath", "/sse", "--messagePath", "/message", "--cors", "--env", "GITHUB_PERSONAL_ACCESS_TOKEN"]