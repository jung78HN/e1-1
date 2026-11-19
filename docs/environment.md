# 환경 설치 및 Git 설정 로그

2026-11-19에 Windows PowerShell에서 수행한 명령과 핵심 출력이다. 경로는 환경 변수로 표시했다.

## Docker와 WSL 설치

```text
PS> where.exe docker
INFO: Could not find files for the given pattern(s).

PS> dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart
Error: 740
Elevated permissions are required to run DISM.
Use an elevated command prompt to complete these tasks.
```

첫 사용자 범위 설치 로그에서는 다음 선행 조건을 확인했다.

```text
PS> Get-Content "$env:LOCALAPPDATA\Docker\install-log.txt" -Tail 18
[WindowsFeaturePreRequisite][E] Required Windows features are not enabled: VirtualMachinePlatform
[InstallWorkflow][E] Prerequisite failed: Docker Desktop requires the "Virtual Machine Platform" Windows feature, which is not enabled on this machine.
```

공식 Docker Desktop 설치 파일은 내려받은 뒤 `Get-AuthenticodeSignature`로 확인했다. 관리자 권한으로 WSL 설치를 실행한 후 사용자 범위 설치를 다시 시도했다. 아래 명령에는 출력에 사용한 변수와 불필요한 경로를 정리했다.

```powershell
$installer = Join-Path $env:TEMP 'e1-1-DockerDesktopInstaller.exe'
(Get-AuthenticodeSignature -LiteralPath $installer).Status
# Valid

$wslInstall = Start-Process -FilePath "$env:WINDIR\System32\wsl.exe" `
    -ArgumentList '--install','--no-distribution' -Verb RunAs -WindowStyle Hidden -Wait -PassThru
'WSL elevated install exit: ' + $wslInstall.ExitCode
# WSL elevated install exit: 0

$process = Start-Process -FilePath $installer `
    -ArgumentList 'install','--user','--quiet','--backend=wsl-2' -WindowStyle Hidden -Wait -PassThru
'Docker Desktop installer exit: ' + $process.ExitCode
# Docker Desktop installer exit: 0
```

```text
PS> wsl.exe --version
WSL 버전: 3.0.5.0
커널 버전: 6.18.58.1-1
Windows 버전: 10.0.26200.9974

PS> wsl.exe --status
기본 버전: 2
가상화가 활성화되지 않은 이 컴퓨터에서는 WSL2를 시작할 수 없습니다.

PS> $docker = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin\docker.exe'
PS> & $docker --version
Docker version 29.9.3, build 5457199

PS> & $docker desktop start --timeout 45
✗Docker Desktop is still starting: context deadline exceeded
Failed to start Docker Desktop

PS> & $docker info --format 'Server={{.ServerVersion}} OS={{.OSType}}'
request returned 500 Internal Server Error for API route and version http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.56/info, check if the server supports the requested API version
Server= OS=
```

```powershell
Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
# True
```

Windows 재시작 이후 `docker info`에서 Linux 엔진의 응답을 확인했다.

```text
PS> wsl.exe --status
기본 배포: docker-desktop
기본 버전: 2

PS> & $docker info --format 'Server={{.ServerVersion}} OS={{.OSType}}'
Server=29.9.3 OS=linux
```

- [Microsoft WSL 설치 문서](https://learn.microsoft.com/windows/wsl/install)
- [Docker Desktop Windows 설치 문서](https://docs.docker.com/desktop/setup/install/windows-install/)

## Git 설정

구성값에서 사용자 이름과 이메일을 마스킹하고 이 과제에 관계된 항목만 기록했다. 기본 브랜치 설정 범위는 현재 저장소다.

```text
PS> git --version
git version 2.56.0.windows.4

PS> git config --local init.defaultBranch main
PS> git symbolic-ref HEAD refs/heads/main
PS> git config --list
init.defaultbranch=master
user.name=<마스킹>
user.email=<마스킹>
init.defaultbranch=main

PS> git branch --show-current
main

PS> gh --version
gh version 2.105.0 (2026-11-17)
```

## GitHub와 VS Code 연동

GitHub CLI에서 기기 인증을 완료했다. 이 저장소에만 GitHub 사용자 이름과 GitHub에서 제공하는 `noreply` 형식의 이메일을 설정했다. 인증 로그의 계정 값은 마스킹했다.

```text
PS> gh auth status --hostname github.com
  ✓ Logged in to github.com account <계정> (keyring)
  - Active account: true
  - Git operations protocol: https

PS> git config --local --list
init.defaultbranch=main
user.name=<마스킹>
user.email=<마스킹>
remote.origin.url=https://github.com/jung78HN/e1-1.git
branch.main.remote=origin
branch.main.merge=refs/heads/main

PS> git branch -vv
* main a7a4081 [origin/main] Verify Docker workstation lab on Windows

PS> git ls-remote origin refs/heads/main
a7a408146e263b0187ee7711b6c93cf7258f7e88    refs/heads/main

PS> git rev-parse HEAD
a7a408146e263b0187ee7711b6c93cf7258f7e88
```

VS Code에서 `e1-1` 폴더를 열고 현재 창의 `GitHub Authentication.log`에서 세션 조회 결과를 확인했다. PowerShell에서 읽은 로그 중 인증 결과 두 줄을 발췌했다.

```powershell
$logs = Join-Path $env:APPDATA 'Code\logs'
$latest = Get-ChildItem $logs -Directory | Sort-Object Name -Descending | Select-Object -First 1
$authLog = Get-ChildItem $latest.FullName -Filter 'GitHub Authentication.log' -File -Recurse |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content -LiteralPath $authLog.FullName -Tail 25
```

```text
2026-11-19 16:56:13.363 [info] Getting sessions for all scopes...
2026-11-19 16:56:13.363 [info] Got 1 sessions for all scopes...
```
