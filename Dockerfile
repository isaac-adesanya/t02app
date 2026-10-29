# Stage 1: build the app using Node.
FROM node:24 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: serve only the built files using nginx.
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
