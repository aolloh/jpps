#!/bin/sh
if ! [ "$1" ]; then
  echo "Syntax: $0 <node> <script> [script...]"
  exit 1
fi
set -eu
NODE=$1
shift

_ssh() {
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l root "$@"
}

grep -w $NODE hosts | {
  while read NODENAME IPV6PREFIX IPV4PRIVATE IPV4ADDR IPV4GATEWAY; do
    export NODENAME IPV6PREFIX IPV4PRIVATE IPV4ADDR IPV4GATEWAY 
    for SCRIPT in $*; do
      IPV6HOST=$IPV6PREFIX::${SCRIPT%%-*}
      echo "********** ⏳️ $SCRIPT ON $IPV6HOST **********"
      if envsubst '$NODENAME $IPV6PREFIX $IPV4PRIVATE $IPV4ADDR $IPV4GATEWAY' < $SCRIPT | _ssh $IPV6HOST sh
      then
        STATUS=✅️
        NEXT=true
      else
        STATUS=⚠️
        NEXT=false
      fi
      echo "********** $STATUS $SCRIPT ON $IPV6HOST **********"
      $NEXT
    done
  done
}
