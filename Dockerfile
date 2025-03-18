# Stage 1: Build the app
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --prefer-offline
COPY . .
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm run build && \
    npm cache clean --force  # 添加缓存清理

# Stage 2: Setup the Nginx Server to serve the app
FROM nginx:1.25.3-alpine
# 改用中科大镜像源注释（单独成行）
RUN --mount=type=cache,target=/var/cache/apk \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk update && apk add curl
COPY --from=build /app/dist /usr/share/nginx/html
RUN echo 'server { listen 80; server_name _; root /usr/share/nginx/html;  location / { try_files $uri /index.html; } }' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# 移除 Stage 2 中的 npm 清理步骤（已在前阶段完成）