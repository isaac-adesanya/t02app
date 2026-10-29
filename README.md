# Project 2: Containerize and Run Locally

This repository contains a static web page served by nginx, a separate Redis service, and an AWS SAM function that runs locally in Docker. No AWS account, credentials, or cloud deployment is required.

## Requirements

- Docker running, with Docker Compose available.
- AWS SAM CLI installed.
- Git and curl.
- A macOS Terminal, Ubuntu/WSL terminal, or the course Path C terminal.
- Port 8080 available.
- Internet access for initial image downloads.

The web build runs inside Docker, so host Node.js is not required for the commands below.

## Build and run

Start in the root of a fresh clone of this repository: the folder containing `Dockerfile` and `compose.yaml`. Use the repository URL submitted with Project 2 to obtain the clone.

### 1. Check the configuration

```bash
docker info
sam --version
grep -c "^FROM" Dockerfile
docker compose config --services
```

The Dockerfile check should print `2`. Compose should list `cache` and `web`, in either order.

### 2. Build the web image

```bash
docker build -t demo:multi .
```

### 3. Start both services

```bash
docker compose up -d --build
docker compose ps
```

Both services should be running, with `cache` marked `healthy`. Compose builds its own web image from the same Dockerfile. The port mapping is host port 8080 to nginx port 80.

### 4. Check both services

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
docker compose exec -T cache redis-cli ping
```

Expected results, respectively:

```text
200
PONG
```

Open http://localhost:8080 in a browser to see **T02 demo**. Redis is checked from inside its container; it does not publish a host port.

### 5. Stop the Compose stack

```bash
docker compose down
```

This removes the Compose containers and network.

### 6. Invoke the local function

```bash
cd local-fn
sam local invoke HelloWorldFunction
sam local invoke HelloWorldFunction -e events/event.json
cd ..
```

The first invocation may download the runtime image. Each invocation should return a response containing:

```json
{"statusCode": 200, "body": "{\"message\":\"hello world\"}"}
```

The second command supplies the scaffolded sample event. These commands run locally; no deployment or AWS login is needed.

## Image-size comparison

To repeat the T02 comparison from the repository root:

```bash
docker build -f Dockerfile.single -t demo:single .
docker build -t demo:multi .
docker images | grep demo
```

Recorded results from my machine, saved in `image-sizes.txt`:

| Image | Disk usage | Content size |
| --- | ---: | ---: |
| demo:multi | 93.2 MB | 26.3 MB |
| demo:single | 1.64 GB | 404 MB |

Using the displayed disk-usage figures, the multi-stage image is approximately 94% smaller. Image sizes may change with platform, Docker version, and base-image updates.

## Debugging and dependency check

With the stack running, these commands show logs, installed software, and container state:

```bash
docker compose logs web
docker compose exec web sh -c 'nginx -v'
docker inspect $(docker compose ps -q web) --format '{{.State.Status}} started={{.State.StartedAt}} restarts={{.RestartCount}}'
```

To repeat the deliberate dependency failure test:

```bash
docker compose stop cache
docker compose ps -a
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
docker compose down
```

The website should still return `200`. This static page does not actually use Redis. The `depends_on` condition controls initial startup readiness; it does not stop the website when Redis stops.

## Main files

- `Dockerfile`: Node build stage followed by the nginx runtime stage.
- `Dockerfile.single`: single-stage image used for comparison.
- `compose.yaml`: web and Redis services, including the Redis healthcheck.
- `index.html`, `package.json`, `package-lock.json`: application and build inputs.
- `.dockerignore`: excludes dependencies, build output, Git history, and `local-fn/` from the web build context.
- `local-fn/`: SAM template, handler, and sample event.
- `image-sizes.txt`: recorded image comparison.
- `rationale.md`: reasons for the base images and service split, with sources.

