# 개발 워크스테이션 실습

터미널과 Git으로 실습 파일을 관리하고, NGINX를 기반으로 정적 페이지를 컨테이너화한다. 같은 이미지에서 웹 컨테이너를 실행해 호스트 포트로 연결하고, 바인드 마운트와 이름 있는 볼륨의 동작을 검증한다.

## 실행 환경

| 항목 | 확인 결과 |
| --- | --- |
| OS | Windows 11 25H2, 빌드 26200.9974 |
| 셸과 터미널 | Git Bash 5.3.15 및 Windows PowerShell |
| WSL | 3.0.5.0, 기본 버전 2 |
| Docker | Docker Desktop 사용자 범위 설치, CLI 29.9.3, 엔진 시작 대기 |
| Git | 2.56.0.windows.4, 과제 저장소 기본 브랜치 `main` |
| VS Code와 GitHub CLI | VS Code 1.145.3, GitHub CLI 2.105.0 |

Windows에서는 Docker Desktop의 WSL 2 백엔드를 사용한다. Linux의 Docker Engine과 macOS의 OrbStack에서도 Docker 스크립트를 실행할 수 있다. Windows에서는 저장소를 연 Git Bash에서 실행한다.

## 수행 체크리스트

- [x] 터미널에서 경로 확인, 탐색, 파일 생성·복사·이름 변경·삭제 및 내용 확인. [터미널 실측 로그](docs/terminal.md)
- [ ] Linux 파일과 디렉터리의 POSIX 권한 변경 전후 검증. [터미널 실습 절차](#터미널과-권한)
- [x] WSL·Docker Desktop 설치 및 Docker CLI 버전 확인. [설치 및 점검 로그](docs/environment.md)
- [ ] 엔진 점검과 `hello-world`, Ubuntu 실행·중지, 이미지·컨테이너 목록, 로그·리소스 조회. [Docker 실습 절차](#docker-실습)
- [x] 커스텀 [Dockerfile](Dockerfile)과 웹 페이지의 [HTML](app/index.html) 및 [CSS](app/style.css) 작성.
- [ ] 이미지 빌드·실행 및 포트가 보이는 브라우저 접속 증거 수집. [Docker 실습 절차](#docker-실습)
- [ ] 바인드 마운트의 수정 반영 및 이름 있는 볼륨의 데이터 영속성 검증. [Docker 실습 절차](#docker-실습)
- [x] Git 사용자 설정 존재 확인 및 과제 저장소에 기본 브랜치 설정. [Git 설정 로그](docs/environment.md#git-설정)
- [ ] GitHub 인증, VS Code 연동 증거 수집 및 GitHub 저장소 제출.

## 터미널과 권한

절대 경로는 `/tmp/.../work/notes.txt`처럼 루트에서 파일까지 지정한다. 같은 파일을 `work` 안에서 열 때는 `notes.txt`라는 상대 경로로 접근할 수 있다.

```bash
bash scripts/terminal-lab.sh
```

Linux에서 실행하면 스크립트가 별도 파일과 디렉터리를 만들고 `stat`을 사용해 변경 전후를 출력한다. Windows에서 Docker 엔진이 실행 중이라면 다음 명령으로 Linux 파일 시스템에서 실습할 수 있다.

```bash
# Git Bash에서 Docker에 전달하는 Linux 경로의 자동 변환을 막는다.
export MSYS_NO_PATHCONV=1
docker run --rm -i ubuntu:24.04 bash -s < scripts/terminal-lab.sh
```

권한 숫자 한 자리는 `r=4`, `w=2`, `x=1`의 합이며, 자리는 소유자·그룹·기타 사용자 순이다. `600`에서 `644`로 바꾸면 파일의 그룹과 기타 사용자에게 읽기 권한이 생긴다. 디렉터리를 `700`에서 `755`로 바꾸면 그룹과 기타 사용자도 목록을 읽고 디렉터리를 통과할 수 있다. 디렉터리에서 `x`는 경로 탐색 권한이다.

## Docker 실습

`nginx:stable-alpine`을 사용해 NGINX와 기본 실행 설정을 재사용한다. `LABEL`은 이미지 이름을 설명하는 메타데이터이고, `COPY`는 기본 문서 루트에 실습 페이지와 CSS를 추가한다. 이미지는 실행에 필요한 파일과 설정의 묶음이며, 컨테이너는 그 이미지를 바탕으로 만들어진 격리된 실행 인스턴스다.

```bash
set -o pipefail
KEEP_WEB=1 bash scripts/docker-lab.sh
```

[Docker 검증 스크립트](scripts/docker-lab.sh)는 다음 명령과 결과를 차례로 터미널에 출력한다.

| 검증 | 확인할 값 |
| --- | --- |
| 엔진 접속 및 기본 운영 | `docker info` 서버 정보, `hello-world` 인사 메시지, `docker images`, `docker ps`, `docker ps -a`, `docker logs`, `docker stats --no-stream` |
| Ubuntu 프로세스 | `docker exec`로 연 셸 종료 후 기존 주 프로세스가 계속 실행되어 `running`. `docker start -ai`로 연결한 주 프로세스의 셸 종료 후 `exited`. |
| 커스텀 이미지와 포트 매핑 | `docker build` 성공 후 `127.0.0.1:8080`을 컨테이너의 `80`으로 연결. `curl -i`로 `200 OK`와 HTML을 확인하고 CSS 응답도 검사. |
| 바인드 마운트 | 같은 컨테이너에서 `127.0.0.1:8081` 응답이 호스트 파일 수정 직후 `bind-before`에서 `bind-after`로 바뀜. |
| 볼륨 | 첫 컨테이너에서 `volume-persisted`를 기록하고 컨테이너 삭제 후 같은 볼륨을 연결한 새 컨테이너에서 다시 읽음. |

`-p 127.0.0.1:8080:80`은 호스트의 루프백 주소에 들어온 요청을 격리된 컨테이너 안의 NGINX 포트로 전달한다. 바인드 마운트는 호스트 경로를 컨테이너에 연결하므로 수정 사항이 즉시 보인다. 이름 있는 볼륨은 Docker가 컨테이너와 별개로 관리하므로 컨테이너를 삭제해도 데이터가 남는다.

`KEEP_WEB=1`이면 스크립트가 마지막에 일시 정지한다. 브라우저에서 `http://127.0.0.1:8080/`을 열어 주소창의 포트와 응답 화면을 함께 캡처한 뒤 터미널에서 Enter를 누르면 실습용 컨테이너·볼륨을 정리한다. 포트 충돌 시 `WEB_PORT=18080 BIND_PORT=18081`을 앞에 붙여 실행할 수 있다.

## Git과 GitHub

Git은 로컬에서 파일 변경의 이력을 커밋으로 관리한다. GitHub는 커밋을 원격에 공유하고 다른 사용자와 협업하는 서비스다. 이 과제 폴더의 기본 브랜치는 `main`이다. [마스킹한 설정 결과](docs/environment.md#git-설정)

GitHub 인증 후 제출용 원격 저장소를 연결하고 `main`을 푸시한다. VS Code의 계정 메뉴에서 GitHub 로그인과 소스 제어의 원격 브랜치 연결을 확인한다. 공유할 캡처에서 계정 정보와 인증 화면은 제외한다.

## 트러블슈팅

1. **Docker CLI 설치 전 `docker`를 찾을 수 없었다.** Docker Desktop 미설치 가능성을 확인하기 위해 `where.exe docker`를 실행했다. 실행 파일이 검색되지 않아 공식 설치 파일의 서명을 검사하고 사용자 범위 설치를 진행했다. 설치 후 CLI 버전이 출력되었다. [설치 로그](docs/environment.md)
2. **첫 Docker Desktop 설치에서 가상 머신 플랫폼이 필요하다는 오류가 발생했다.** `install-log.txt`에서 `VirtualMachinePlatform` 선행 조건을 확인했고, 일반 셸에서 실행한 DISM은 오류 740을 반환했다. 관리자 모드로 WSL 설치를 실행한 후 Docker Desktop을 다시 설치했다. WSL은 설치되었으나 상태 점검에서 WSL 2 가상화가 아직 준비되지 않았고 엔진 시작은 시간 초과되었다. Windows 재시작 후 WSL 상태를 다시 확인해야 한다. [실측 로그](docs/environment.md)
