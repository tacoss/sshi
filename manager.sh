#!/bin/bash

set -eu

AVAIL_CMDS="$(cat $0 | awk -F'\\|.*##' '/[a-z|]+\) ##(.+?)/{printf "\033[36m%10s\033[0m %s\n",$1,$2}')"
AVAIL_SSHS=""

SSHI_FILE="$HOME/.sshiconf"

if [[ -f $SSHI_FILE ]]; then
  AVAIL_SSHS="$(cat $SSHI_FILE)"
fi

exists () {
  if [[ -z "${2:-}" ]]; then
    echo "Provide a valid name, e.g. \`sshi $1 NAME\`"
    exit 1
  fi

  if [[ -z "$(echo $AVAIL_SSHS | grep $2)" ]]; then
    return 1
  fi
  return 0
}

cmd="${1:-}"
name="${2:-}"
conn="${3:-}"

if [[ $cmd =~ @(.+) ]]; then
  name="${BASH_REMATCH[1]}"

  if ! exists $cmd $name; then
    echo "Connection '$name' does not exists!"
    exit 1
  else
    echo "$AVAIL_SSHS" | awk "/^$name /{print \$2}"
    exit 0
  fi
fi

case $cmd in
  add|ad|a) ## Save SSH connection for later
    if ! exists $cmd $name; then
      if [[ $conn =~ ^.+@.+$ ]]; then
        echo "$name $conn" >> $SSHI_FILE
        exit 0
      else
        echo "Provide a valid connection, e.g. \`sshi $cmd $name user@host\`"
        exit 1
      fi
    else
      echo "Connection '$name' already exists!"
      exit 1
    fi
    ;;
  del|de|d) ## Remove from saved connections
    if ! exists $cmd $name; then
      echo "Connection '$name' does not exists!"
      exit 1
    else
      echo "$AVAIL_SSHS" | grep -vE "^$name " >> $SSHI_FILE
      exit 0
    fi
    ;;
  ls|l) ## List registered connections
    echo "Registered connections:"
    echo "$AVAIL_SSHS" | awk '{printf "\033[36m%10s\033[0m %s\n",$1,$2}'
    exit 0
    ;;
  *)
    echo "Available commands:"
    echo "$AVAIL_CMDS"
    exit 1
    ;;
esac
