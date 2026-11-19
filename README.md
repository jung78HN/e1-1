# 개발 워크스테이션 실습

터미널과 Git으로 실습 파일을 관리하고, NGINX를 기반으로 정적 페이지를 컨테이너화한다. 같은 이미지에서 웹 컨테이너를 실행해 호스트 포트로 연결하고, 바인드 마운트와 이름 있는 볼륨의 동작을 검증한다.

## 디렉터리 구조와 설계 기준

```text
.
├── app/                     # NGINX가 제공하는 HTML과 CSS
├── scripts/                 # 터미널 및 Docker 재현 스크립트
│   ├── terminal-lab.sh
│   └── docker-lab.sh
├── docs/                    # 실행 로그, 타임스탬프, 브라우저 캡처
├── Dockerfile               # NGINX 이미지 빌드 정의
├── .dockerignore            # Docker 빌드 컨텍스트의 포함 범위
├── .gitattributes           # 셸 스크립트와 Dockerfile의 LF 설정
└── README.md                # 실행·검증·장애 대응 안내
```

배포할 소스는 `app/`, 실습을 재현하는 명령은 `scripts/`, 평가 증빙은 `docs/`에 둔다. 루트의 [.dockerignore](.dockerignore)는 Docker 빌드 컨텍스트를 `Dockerfile`과 `app/`으로 제한한다. 웹 파일이 바뀌면 `COPY app/` 레이어를 다시 만들고, 문서나 로그의 변경은 해당 레이어의 캐시 키에 영향을 주지 않는다.

## 실행 환경

| 항목 | 확인 결과 |
| --- | --- |
| OS | Windows 11 25H2, 빌드 26200.9974 |
| 셸과 터미널 | Git Bash 5.3.15 및 Windows PowerShell |
| WSL | 3.0.5.0, 기본 버전 2 |
| Docker | Docker Desktop 사용자 범위 설치, CLI·Linux 엔진 29.9.3 |
| Git | 2.56.0.windows.4, 과제 저장소 기본 브랜치 `main` |
| VS Code와 GitHub CLI | VS Code 1.145.3, GitHub CLI 2.105.0 |

Windows에서는 Docker Desktop의 WSL 2 백엔드를 사용한다. Linux의 Docker Engine과 macOS의 OrbStack에서도 Docker 스크립트를 실행할 수 있다. Windows에서는 저장소를 연 Git Bash에서 실행한다.

## 수행 체크리스트

- [x] 터미널에서 경로 확인, 탐색, 파일 생성·복사·이름 변경·삭제 및 내용 확인. [타임스탬프가 포함된 전체 세션](docs/terminal-session.txt)
- [x] Linux 파일과 디렉터리의 POSIX 권한을 `ls -l`, `ls -ld`, `stat`으로 변경 전후 검증. [권한 실측 로그](docs/terminal.md#linux-파일과-디렉터리-권한)
- [x] WSL·Docker Desktop 설치 및 Docker CLI 버전 확인. [설치 및 점검 로그](docs/environment.md)
- [x] 엔진 점검과 `hello-world`, Ubuntu 실행·중지, 이미지·컨테이너 목록, 로그·리소스 조회. [Docker 실측 로그](docs/docker.md), [엔진 요약 및 종료 코드](docs/docker.md#엔진-요약과-hello-world-종료-코드)
- [x] 커스텀 [Dockerfile](Dockerfile)과 웹 페이지의 [HTML](app/index.html) 및 [CSS](app/style.css) 작성.
- [x] 이미지 빌드·실행 및 포트가 보이는 브라우저 접속 증거 수집. [브라우저 캡처](docs/browser-proof.png)
- [x] 바인드 마운트의 수정 반영 및 이름 있는 볼륨의 데이터 영속성 검증. [Docker 실측 로그](docs/docker.md)
- [x] Git 사용자 이름과 비공개 이메일 설정 및 기본 브랜치 `main` 지정. [Git 설정 로그](docs/environment.md#git-설정)
- [x] GitHub CLI와 VS Code GitHub 인증 및 공개 저장소 `main` 연동. [인증과 원격 연결 로그](docs/environment.md#github와-vs-code-연동)

## 터미널과 권한

절대 경로는 `/tmp/.../work/notes.txt`처럼 루트에서 파일까지 지정한다. 같은 파일을 `work` 안에서 열 때는 `notes.txt`라는 상대 경로로 접근할 수 있다. 저장소 루트에서는 `bash scripts/terminal-lab.sh`처럼 상대 경로를 쓰고, Docker의 바인드 마운트 원본은 스크립트에서 `pwd -P`로 절대 경로를 얻는다.

```bash
bash scripts/terminal-lab.sh
```

Linux에서 실행하면 스크립트가 별도 파일과 디렉터리를 만들고 `ls -l`, `ls -ld`, `stat`으로 변경 전후를 출력한다. Windows에서 Docker 엔진이 실행 중이라면 다음 명령으로 Linux 파일 시스템에서 실습할 수 있다.

```bash
# Git Bash에서 Docker에 전달하는 Linux 경로의 자동 변환을 막는다.
export MSYS_NO_PATHCONV=1
docker run --rm -i ubuntu:24.04 bash -s < scripts/terminal-lab.sh
```

권한 숫자 한 자리는 `r=4`, `w=2`, `x=1`의 합이며, 자리는 소유자·그룹·기타 사용자 순이다. 디렉터리에서 `x`는 경로 탐색 권한이다.

| 대상 | 변경 전 | 변경 후 | 그룹과 기타 사용자에게 추가된 권한 |
| --- | --- | --- | --- |
| 파일 `permissions/example.txt` | `600` (`-rw-------`) | `644` (`-rw-r--r--`) | 파일 내용 읽기 |
| 디렉터리 `permissions` | `700` (`drwx------`) | `755` (`drwxr-xr-x`) | 목록 읽기와 경로 탐색 |

## Docker 실습

`nginx:stable-alpine`을 사용해 NGINX와 기본 실행 설정을 재사용한다. `LABEL`은 이미지 이름을 설명하는 메타데이터이고, `COPY`는 기본 문서 루트에 실습 페이지와 CSS를 추가한다. 이미지는 실행에 필요한 파일과 설정의 묶음이며, 컨테이너는 그 이미지를 바탕으로 만들어진 격리된 실행 인스턴스다.

1. `docker build`로 `app/`의 파일을 `e11-workstation:1.0` 이미지에 포함한다.
2. `docker run`으로 같은 이미지에서 웹 컨테이너와 바인드 마운트 실습 컨테이너를 각각 만든다.
3. 웹 이미지에 소스 변경을 넣으려면 이미지를 다시 빌드하고 컨테이너를 새로 만든다. 바인드 마운트 대상의 호스트 파일을 바꾸면 실행 중인 컨테이너에 바로 반영된다.

```bash
set -o pipefail
KEEP_WEB=1 bash scripts/docker-lab.sh
```

[Docker 검증 스크립트](scripts/docker-lab.sh)는 다음 명령과 결과를 차례로 터미널에 출력한다. [실행 로그와 두 번째 포트의 브라우저 캡처](docs/docker.md)

| 검증 | 확인할 값 |
| --- | --- |
| 엔진 접속 및 기본 운영 | `docker info` 서버 정보, `hello-world` 인사 메시지, `docker images`, `docker ps`, `docker ps -a`, `docker logs`, `docker stats --no-stream` |
| Ubuntu 프로세스 | `docker exec`로 연 셸 종료 후 기존 주 프로세스가 계속 실행되어 `running`. `docker start -ai`로 연결한 주 프로세스의 셸 종료 후 `exited`. |
| 커스텀 이미지와 포트 매핑 | `docker build` 성공 후 `127.0.0.1:8080`을 컨테이너의 `80`으로 연결. `curl -i`로 `200 OK`와 HTML을 확인하고 CSS 응답도 검사. |
| 바인드 마운트 | 같은 컨테이너에서 `127.0.0.1:8081` 응답이 호스트 파일 수정 직후 `bind-before`에서 `bind-after`로 바뀜. |
| 볼륨 | 첫 컨테이너에서 `volume-persisted`를 기록하고 컨테이너 삭제 후 같은 볼륨을 연결한 새 컨테이너에서 다시 읽음. |

| 환경 변수 | 기본값 | 동작 |
| --- | --- | --- |
| `WEB_PORT` | `8080` | 이미지에 포함된 웹 페이지를 여는 호스트 포트 |
| `BIND_PORT` | `8081` | 바인드 마운트 실습의 호스트 포트 |
| `KEEP_WEB` | `0` | `0`이면 검증 후 정리하고, `1`이면 브라우저 캡처를 위해 Enter 입력까지 컨테이너를 유지 |

### 네트워크 네임스페이스와 포트 포워딩

기본 브리지 네트워크에서 각 컨테이너는 별도의 네트워크 네임스페이스를 갖는다. 네임스페이스는 네트워크 인터페이스, IP 주소, 라우팅 테이블과 소켓을 격리한다. 따라서 여러 컨테이너가 각각 내부 `80/tcp`에서 동시에 요청을 받을 수 있다. `-p 127.0.0.1:8080:80`은 호스트의 루프백 `8080/tcp`로 들어온 요청을 해당 컨테이너의 네임스페이스 안에 있는 NGINX의 `80/tcp`로 전달한다. 같은 이미지의 두 번째 컨테이너에는 호스트 `8081/tcp`를 연결했다. [Docker 포트 매핑 문서](https://docs.docker.com/engine/network/port-publishing/)

| 이미지 태그와 ID | 컨테이너 역할과 ID | 호스트 → 컨테이너 |
| --- | --- | --- |
| `e11-workstation:1.0` · `9629660060aa` | 웹 · `a22464ec9f0a` | `127.0.0.1:8080` → `80/tcp` |
| `e11-workstation:1.0` · `9629660060aa` | 바인드 마운트 · `3d7b46945d39` | `127.0.0.1:8081` → `80/tcp` |

`curl -fsS -i http://127.0.0.1:8080/`에서 `HTTP/1.1 200 OK`, `Content-Type: text/html`, `Content-Length: 559`를 확인했다. 본문에는 `개발 워크스테이션 실습` 제목과 `커스텀 NGINX 이미지의 정적 페이지입니다.` 문장이 포함됐다. [응답 전체 및 브라우저 캡처](docs/docker.md)

`KEEP_WEB=1`로 실행했으면 브라우저에서 출력된 주소를 열고 캡처가 끝난 뒤 Enter를 눌러 실습용 리소스를 정리한다.

### 바인드 마운트와 이름 있는 볼륨

| 방식 | 이 실습의 연결 | 사용 시 고려할 점 |
| --- | --- | --- |
| 바인드 마운트 | 호스트 임시 `content/` → NGINX의 `/usr/share/nginx/html` | 호스트에서 바로 편집·백업할 수 있다. 경로, 파일 권한, Docker Desktop의 파일 공유 설정에 영향을 받는다. `readonly`는 컨테이너에서 호스트 파일을 쓰는 것을 막는다. |
| 이름 있는 볼륨 | `e11-1795074388-1300-data` → `-volume-before`와 `-volume-after` 컨테이너의 `/data` | Docker가 저장 위치를 관리한다. 컨테이너를 교체해도 남으며, 백업할 때는 별도 컨테이너에서 마운트해 데이터를 추출할 수 있다. |

첫 Ubuntu 컨테이너가 `/data/marker.txt`에 `volume-persisted`를 기록했다. 그 컨테이너를 삭제하고 같은 볼륨을 새 Ubuntu 컨테이너에 연결한 뒤 동일한 값을 읽었다. [볼륨 실측 로그](docs/docker.md)

### 포트 충돌 진단과 복구

1. `port is already allocated` 또는 `address already in use`가 나오면, PowerShell에서 호스트의 `LISTENING` 행과 Docker 컨테이너의 매핑을 확인한다. 마지막 열이 호스트 프로세스의 PID다.

   ```powershell
   $port = 8080
   $listeners = netstat.exe -ano -p tcp | Select-String -Pattern "^\s+TCP\s+\S+:$port\s+\S+\s+LISTENING\s+\d+\s*$"
   $listeners
   $listeners | ForEach-Object { Get-Process -Id (($_.Line.Trim() -split '\s+')[-1]) }
   docker ps --format '{{.Names}} {{.Ports}}' | Select-String -SimpleMatch ":$port->"
   ```

2. 본인이 실행한 이전 실습 컨테이너가 점유 중이면 `docker stop <컨테이너명>`으로 중지한다. Docker Desktop의 `com.docker.backend`가 PID로 나오면 `docker ps` 결과에서 해당 컨테이너를 찾는다. 일반 앱이 소유한 포트라면 해당 앱을 정상 종료하거나 설정에서 리스닝 포트를 변경한다. 다른 서비스가 사용 중인 포트는 두고 실습의 호스트 포트만 변경한다.
3. 점유를 해제했다면 실습 스크립트를 원래 설정으로 다시 실행한다. 대체 포트를 사용한다면 Git Bash에서 아래처럼 실행하고, 스크립트가 멈춘 상태에서 다른 터미널로 HTTP 응답을 확인한다.

   ```bash
   WEB_PORT=18080 BIND_PORT=18081 KEEP_WEB=1 bash scripts/docker-lab.sh
   # 다른 터미널에서 실행
   curl -fsS -i http://127.0.0.1:18080/
   ```

실습용 포트에서 충돌로 종료 코드 `125`가 반환되는 것을 확인했다. 기존 실습 컨테이너를 중지하고 같은 포트로 다시 실행하니 `HTTP 200`이 반환됐다. [충돌 재현과 복구 로그](docs/docker.md#호스트-포트-충돌-재현과-복구) · [Windows netstat 문서](https://learn.microsoft.com/windows-server/administration/windows-commands/netstat)

## Git과 GitHub

Git은 로컬에서 파일 변경의 이력을 커밋으로 관리한다. GitHub는 커밋을 원격에 공유하고 다른 사용자와 협업하는 서비스다. 이 과제 폴더의 기본 브랜치는 `main`이다. [마스킹한 설정 결과](docs/environment.md#git-설정)

GitHub 인증 후 제출용 원격 저장소를 `origin`에 연결하고 `main`을 푸시했다. VS Code의 GitHub Authentication 로그에서 활성 세션을, Git에서 로컬 `main`이 `origin/main`을 추적하는 것을 확인했다. [인증과 원격 연결 로그](docs/environment.md#github와-vs-code-연동)

원격 `main`의 최신 커밋과 기존 제출 검증 시점의 기준 커밋을 GitHub에서 조회할 수 있다. [공개 저장소](https://github.com/jung78HN/e1-1) · [원격 main의 최신 커밋](https://github.com/jung78HN/e1-1/commit/main) · [제출 검증 기준 커밋 `653404a`](https://github.com/jung78HN/e1-1/commit/653404a4bfadcb915395c866701139e429b3cdb4)

## 트러블슈팅

| 문제 | 원인 가설 | 확인 명령과 결과 | 조치와 재검증 |
| --- | --- | --- | --- |
| `docker` 명령을 찾을 수 없음 | Docker Desktop 미설치 | `where.exe docker`가 실행 파일을 찾지 못함 | 공식 설치 파일의 서명을 확인해 설치하고 `docker --version` 확인. [설치 로그](docs/environment.md#docker와-wsl-설치) |
| Docker Desktop 설치 또는 시작 실패 | `VirtualMachinePlatform` 미활성화 | `install-log.txt`에 선행 조건 실패 기록. 일반 셸의 DISM은 오류 `740` 반환 | 관리자 모드로 WSL 설치 후 Docker Desktop 재설치 및 Windows 재시작. `docker info`가 Linux 엔진 정보 반환. [설치 로그](docs/environment.md#docker와-wsl-설치) |
| Git Bash에서 `curl` 오류 `23` | Windows `curl -o`에 전달한 POSIX 임시 경로를 열 수 없음 | 페이지 요청을 받아 응답 바이트를 쓰는 단계에서 실패 | 셸 출력 리디렉션으로 파일을 열고 재실행해 `200 OK`와 HTML을 확인. [오류와 해결 로그](docs/docker.md#git-bash의-curl-출력-경로-오류) |
