# Project 2 Rationale

## Base image and multi-stage build

I chose `nginx:alpine` for the final image because this application only needs to serve a static HTML page. The official nginx image provides a web server, and its Alpine variant provides a small base without adding a full development environment. A larger Node image would keep tools that the running website does not need.

The first stage uses `node:24` to run `npm ci` and `npm run build`. In this project, the build command copies the HTML file into a build folder. The second stage copies that output into nginx's web directory. Docker's multi-stage build documentation explains that copying selected artifacts between stages allows build tools to be left out of the final image.

My recorded results in `image-sizes.txt` were:

| Image | Disk usage | Content size |
| --- | ---: | ---: |
| Multi-stage | 93.2 MB | 26.3 MB |
| Single-stage | 1.64 GB | 404 MB |

Using the rounded disk-usage figures and 1.64 GB as approximately 1,640 MB, the reduction is `(1640 - 93.2) / 1640 × 100 ≈ 94.3%`. The single-stage image is about 17.6 times larger. It includes Node and the installed `http-server`, while the multi-stage image contains nginx and the built page. This comparison measures those two complete approaches; it does not isolate Alpine's contribution or compare two nginx variants. These are local measurements, and future builds may differ as image tags are updated.

## Separate web and cache services

I used `redis:7-alpine` as a separate service because serving web pages and providing a cache are different responsibilities. The official Redis image supplies an existing cache implementation instead of requiring me to write one or install Redis inside the web image. Keeping the services separate also lets me inspect, stop, or replace Redis without rebuilding the website.

Compose runs `redis-cli ping` as the cache healthcheck. The web service uses `depends_on` with `condition: service_healthy`, so Compose waits for that check to pass before starting web. Docker's startup-order documentation describes this distinction between a container being running and its service being ready.

Redis is a demonstration dependency here: the static page does not read or write cached data. During the T05 test, stopping Redis left the website responding with HTTP 200. This shows that startup ordering alone does not create an ongoing application dependency.

In the course's service-model framing, containers sit between IaaS and PaaS. I still manage the image choices, configuration, ports, and container lifecycle, while accepting nginx and Redis as pre-built software. This is not a managed cloud cache: I remain responsible for running Redis. The service split makes that choice clear by combining my web build with an existing dependency.

## References

- Docker. *Multi-stage builds*. https://docs.docker.com/build/building/multi-stage/
- Docker. *Control startup and shutdown order in Compose*. https://docs.docker.com/compose/how-tos/startup-order/
- Docker Hub. *nginx — Docker Official Image*. https://hub.docker.com/_/nginx
- Docker Hub. *redis — Docker Official Image*. https://hub.docker.com/_/redis

