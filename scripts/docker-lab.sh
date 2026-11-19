#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
run="e11-$(date +%s)-$$"
image=e11-workstation:1.0
web="${run}-web"
ubuntu="${run}-ubuntu"
attached="${run}-attached"
bind="${run}-bind"
before="${run}-volume-before"
after="${run}-volume-after"
volume="${run}-data"
web_port=${WEB_PORT:-8080}
bind_port=${BIND_PORT:-8081}
scratch=$(mktemp -d)

cleanup() {
  docker rm -f "$web" "$ubuntu" "$attached" "$bind" "$before" "$after" >/dev/null 2>&1 || true
  docker volume rm "$volume" >/dev/null 2>&1 || true
  rm -rf -- "$scratch"
}

wait_for_http() {
  local url=$1
  for attempt in {1..30}; do
    if curl -fsS --max-time 2 "$url" -o "$scratch/response.txt" 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  curl -fsS --max-time 2 "$url" -o "$scratch/response.txt"
}

# Git Bash otherwise rewrites paths inside Linux containers.
export MSYS_NO_PATHCONV=1
trap cleanup EXIT
set -x
docker --version
docker info --format 'Server={{.ServerVersion}} OS={{.OSType}} Architecture={{.Architecture}} Storage={{.Driver}}'

docker pull hello-world
docker run --rm hello-world
docker pull ubuntu:24.04
docker run -d --name "$ubuntu" ubuntu:24.04 sleep infinity
docker exec "$ubuntu" sh -c 'ls -d /etc /tmp; echo ubuntu-exec-exit; exit'
docker inspect --format 'After exec exit: {{.State.Status}}' "$ubuntu"
test "$(docker inspect --format '{{.State.Status}}' "$ubuntu")" = running
docker create -i --name "$attached" ubuntu:24.04 sh
printf '%s\n' 'echo ubuntu-main-shell-exit' 'exit' | docker start -ai "$attached"
docker inspect --format 'After attached PID 1 exits: {{.State.Status}}' "$attached"
test "$(docker inspect --format '{{.State.Status}}' "$attached")" = exited
docker stop "$ubuntu"

docker build -t "$image" .
docker images "$image"
docker run -d --name "$web" -p "127.0.0.1:${web_port}:80" "$image"
wait_for_http "http://127.0.0.1:${web_port}/"
curl -fsS -i "http://127.0.0.1:${web_port}/"
grep -F '커스텀 NGINX 이미지의 정적 페이지입니다.' "$scratch/response.txt"
curl -fsS "http://127.0.0.1:${web_port}/style.css" | grep -F 'color-scheme: dark;'

mkdir "$scratch/content"
printf '%s\n' 'bind-before' > "$scratch/content/index.html"
bind_source=$(cd "$scratch/content" && pwd -P)
if [[ $(uname -s) == MINGW* ]]; then
  bind_source=$(cygpath -m "$bind_source")
fi
docker run -d --name "$bind" -p "127.0.0.1:${bind_port}:80" \
  --mount "type=bind,source=${bind_source},target=/usr/share/nginx/html,readonly" "$image"
wait_for_http "http://127.0.0.1:${bind_port}/"
curl -fsS "http://127.0.0.1:${bind_port}/" | grep -Fx 'bind-before'
printf '%s\n' 'bind-after' > "$scratch/content/index.html"
curl -fsS "http://127.0.0.1:${bind_port}/" | grep -Fx 'bind-after'
docker inspect --format 'Bind container still {{.State.Status}}: {{.Id}}' "$bind"

docker volume create "$volume"
docker run --name "$before" --mount "type=volume,source=${volume},target=/data" ubuntu:24.04 \
  sh -c 'printf "%s\n" "volume-persisted" > /data/marker.txt && cat /data/marker.txt'
docker rm "$before"
docker run --name "$after" --mount "type=volume,source=${volume},target=/data" ubuntu:24.04 \
  cat /data/marker.txt | grep -Fx 'volume-persisted'

docker ps --filter "name=${run}"
docker ps -a --filter "name=${run}"
docker logs --tail 12 "$web"
docker stats --no-stream "$web" "$bind"

if [[ ${KEEP_WEB:-0} == 1 ]]; then
  set +x
  printf '브라우저 캡처 주소: http://127.0.0.1:%s/\n' "$web_port"
  read -r -p '캡처를 저장한 뒤 Enter를 누르면 실습 리소스를 정리합니다. '
fi
