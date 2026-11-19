# 터미널 수행 로그

2026-11-19에 Windows의 Git Bash에서 실행했다. 임시 폴더 이름과 파일 소유자 및 그룹 정보는 마스킹했다.

```text
$ bash scripts/terminal-lab.sh
+ uname -s
MINGW64_NT-10.0-26200
+ cd /tmp/<실습폴더>
+ pwd
/tmp/<실습폴더>
+ mkdir work
+ cd work
+ touch .hidden empty.txt
+ printf '%s\n' 'Developer workstation lab'
+ ls -la
total 1
drwxr-xr-x 1 <사용자> <그룹>  0 Nov 19 16:14 .
drwxr-xr-x 1 <사용자> <그룹>  0 Nov 19 16:14 ..
-rw-r--r-- 1 <사용자> <그룹>  0 Nov 19 16:14 .hidden
-rw-r--r-- 1 <사용자> <그룹>  0 Nov 19 16:14 empty.txt
-rw-r--r-- 1 <사용자> <그룹> 26 Nov 19 16:14 notes.txt
+ cat notes.txt
Developer workstation lab
+ wc -c empty.txt
0 empty.txt
+ cp notes.txt copy.txt
+ mv copy.txt renamed.txt
+ ls -l renamed.txt
-rw-r--r-- 1 <사용자> <그룹> 26 Nov 19 16:14 renamed.txt
+ rm renamed.txt
+ test '!' -e renamed.txt
+ ls -la
total 1
drwxr-xr-x 1 <사용자> <그룹>  0 Nov 19 16:14 .
drwxr-xr-x 1 <사용자> <그룹>  0 Nov 19 16:14 ..
-rw-r--r-- 1 <사용자> <그룹>  0 Nov 19 16:14 .hidden
-rw-r--r-- 1 <사용자> <그룹>  0 Nov 19 16:14 empty.txt
-rw-r--r-- 1 <사용자> <그룹> 26 Nov 19 16:14 notes.txt
++ uname -s
+ [[ MINGW64_NT-10.0-26200 == Linux ]]
+ rm -rf -- /tmp/<실습폴더>
```

## Linux 파일과 디렉터리 권한

Ubuntu 컨테이너 안의 Linux 파일 시스템에서 `chmod`를 실행했다. 출력에서 권한 변경 구간을 발췌했다.

```text
$ MSYS_NO_PATHCONV=1 docker run --rm -i ubuntu:24.04 bash -s < scripts/terminal-lab.sh
+ mkdir permissions
+ touch permissions/example.txt
+ chmod 600 permissions/example.txt
+ chmod 700 permissions
+ stat -c '%a %A %n' permissions permissions/example.txt
700 drwx------ permissions
600 -rw------- permissions/example.txt
+ chmod 644 permissions/example.txt
+ chmod 755 permissions
+ stat -c '%a %A %n' permissions permissions/example.txt
755 drwxr-xr-x permissions
644 -rw-r--r-- permissions/example.txt
+ rm -rf -- /tmp/<실습폴더>
```
