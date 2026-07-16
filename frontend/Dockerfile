# Stage 1: build the static assets
# (node:20-slim, not -alpine: some Docker Desktop/Apple Silicon combinations
# hit a segfault in `npm ci` under alpine's musl libc + V8 JIT)
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: serve them behind an nginx proxy that also forwards /api to the backend
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
