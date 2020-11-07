#!/bin/bash

set -eu

AVAIL_CMDS="$(cat $0 | awk -F'\\|.*##' '/[a-z|]+\) ##(.+?)/{printf "%-6s %s\n",$1,$2}')"
AVAIL_SSHS=""

SSHI_BIN="$(basename $0)"
SSHI_FILE="$HOME/.sshiconf"

if [[ -f $SSHI_FILE ]]; then
  AVAIL_SSHS="$(cat $SSHI_FILE)"
fi

exists () {
  if [[ -z "${2:-}" ]]; then
    echo "Provide a valid name, e.g. \`$SSHI_BIN $1 NAME\`"
    exit 1
  fi

  if [[ -z "$(echo $AVAIL_SSHS | grep "\b$2 ")" ]]; then
    return 1
  fi
  return 0
}

cmd="${1:-}"
name="${2:-}"
extra="${3:-}"

case $cmd in
  save|s) ## Register SSH endpoint for later
    if ! exists $cmd $name; then
      if [[ $extra =~ ^.+@ ]]; then
        echo "$name $extra $(echo "$@" | cut -d ' ' -f 4-)" >> $SSHI_FILE
        echo "Endpoint '$name' was added"
        exit 0
      else
        echo "Provide a valid endpoint, e.g. \`$SSHI_BIN $cmd $name user@host\`"
        exit 1
      fi
    else
      echo "Endpoint '$name' already exists!"
      exit 1
    fi
    ;;
  del|d) ## Remove from saved endpoints
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
    if [[ -z "$AVAIL_SSHS" ]]; then
      echo "No registered endpoints"
    else
      echo "Registered endpoints:"
      echo "$AVAIL_SSHS" | awk '{printf "  @%-13s  %s\n",$1,$2}'
    fi
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
        flags="$(echo "$AVAIL_SSHS" | awk "/^$name /" | cut -d ' ' -f 3-)"
        expand="$(echo "$@" | sed "s|@$name|$conn|g")"
        command="$(echo "$expand" | awk '{print $1}')"
        arguments="$(echo "$expand" | cut -d ' ' -f 2-)"

        if [[ "$#" -lt 2 ]] || [[ $cmd =~ @ ]]; then
          ssh $flags -qt $expand || exit 2
        else
          exec $command $flags $arguments || exit 2
        fi
        exit 0
      fi
    fi

    if [[ ! -z "$cmd" ]]; then
      echo "Unsupported '$cmd', type \`$SSHI_BIN\` without arguments for usage info"
      exit 1
    fi

    echo "Usage:"
    echo "  $SSHI_BIN [CMD|@NAME] [...]"
    echo
    echo "Examples:"
    echo "  $SSHI_BIN save local root@localhost"
    echo "  $SSHI_BIN del my-site"
    echo
    echo "Execute commands through SSH, e.g."
    echo "  $SSHI_BIN @my-site du -h /tmp"
    echo
    echo "Endpoints are replaced on the fly, e.g."
    echo "  $SSHI_BIN scp index.html @my-site:/var/www"
    echo "    => scp index.html root@localhost:/var/www"
    echo
    echo "Available commands:"
    echo "$AVAIL_CMDS"
    exit 1
    ;;
esac
