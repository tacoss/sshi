#!/bin/bash

set -eu

AVAIL_CMDS="$(cat $0 | awk -F'\\|.*##' '/[a-z|]+\) ##(.+?)/{printf "%5s  %s\n",$1,$2}')"
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
extra="${3:-}"

case $cmd in
  add|ad|a) ## Save SSH endpoint for later
    if ! exists $cmd $name; then
      if [[ $extra =~ ^.+@.+$ ]]; then
        echo "$name $extra" >> $SSHI_FILE
        echo "Endpoint '$name' was added"
        exit 0
      else
        echo "Provide a valid endpoint, e.g. \`sshi $cmd $name user@host\`"
        exit 1
      fi
    else
      echo "Endpoint '$name' already exists!"
      exit 1
    fi
    ;;
  del|de|d) ## Remove from saved endpoints
    if ! exists $cmd $name; then
      echo "Endpoint '$name' does not exists!"
      exit 1
    else
      echo "$AVAIL_SSHS" | grep -vE "^$name " > $SSHI_FILE
      echo "Endpoint '$name' was deleted"
      exit 0
    fi
    ;;
  ls|l) ## List registered endpoints
    echo "Registered endpoints:"
    echo "$AVAIL_SSHS" | awk '{printf "  @%-15s  %s\n",$1,$2}'
    exit 0
    ;;
  *)
    if [[ $@ =~ @([^:\ /]*) ]]; then
      name="${BASH_REMATCH[1]}"

      if ! exists - $name; then
        echo "Endpoint '$name' does not exists!"
        exit 1
      else
        conn="$(echo "$AVAIL_SSHS" | awk "/^$name /{print \$2}")"
        value="$(echo $@ | sed "s/@$name/$conn/g")"

        if [ "$#" -ge 2 ]; then
          exec $value
        else
          echo $conn
        fi
        exit 0
      fi
    fi

    echo "Usage:"
    echo "  sshi [CMD|@NAME] [...]"
    echo
    echo "Examples:"
    echo "  sshi add local root@localhost"
    echo "  sshi del my-site"
    echo
    echo "Endpoints are replaced on the fly, e.g."
    echo "  sshi scp index.html @my-site:/var/www"
    echo "    => scp index.html root@localhost:/var/www"
    echo
    echo "Available commands:"
    echo "$AVAIL_CMDS"
    exit 1
    ;;
esac
