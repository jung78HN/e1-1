FROM nginx:stable-alpine

LABEL org.opencontainers.image.title="Developer Workstation Lab"
COPY app/ /usr/share/nginx/html/
