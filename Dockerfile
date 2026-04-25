# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS builder
WORKDIR /app

# Install dependencies first to maximize layer caching.
COPY package*.json ./
RUN npm ci

COPY . .

# Optional token used during build-time GitHub API fetches.
RUN --mount=type=secret,id=gh_token \
  GITHUB_TOKEN="$(cat /run/secrets/gh_token 2>/dev/null || true)" npm run build

FROM nginx:1.27-alpine AS runtime
WORKDIR /usr/share/nginx/html

COPY --from=builder /app/dist ./

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
