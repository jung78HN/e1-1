#!/usr/bin/env bash
set -euo pipefail

# Work in a disposable directory and show the commands as they execute.
lab=$(mktemp -d)
trap 'rm -rf -- "$lab"' EXIT
set -x
uname -s
cd "$lab"
pwd
mkdir work
cd work
touch .hidden empty.txt
printf '%s\n' 'Developer workstation lab' > notes.txt
ls -la
cat notes.txt
wc -c empty.txt
cp notes.txt copy.txt
mv copy.txt renamed.txt
ls -l renamed.txt
rm renamed.txt
test ! -e renamed.txt
ls -la

# Git Bash's Windows compatibility layer cannot demonstrate POSIX modes.
if [[ $(uname -s) == Linux ]]; then
  mkdir permissions
  touch permissions/example.txt
  chmod 600 permissions/example.txt
  chmod 700 permissions
  ls -l -- permissions/example.txt
  ls -ld -- permissions
  stat -c '%a %A %n' permissions permissions/example.txt
  chmod 644 permissions/example.txt
  chmod 755 permissions
  ls -l -- permissions/example.txt
  ls -ld -- permissions
  stat -c '%a %A %n' permissions permissions/example.txt
fi
