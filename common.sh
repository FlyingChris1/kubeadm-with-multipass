#!/bin/bash

set -euo pipefail

IMAGE="24.04"
CPUS="2"
MEMORY="4G"
DISK="20G"

wait_for_instance() {
  local name="$1"

  echo "Waiting for $name SSH..."

  for i in $(seq 1 60); do
    

    if multipass exec "$name" -- hostname; then
      echo "$name is reachable"
      return 0
    fi

    sleep 2
  done

  echo "ERROR: $name is not reachable via multipass SSH"

  multipass list || true
  multipass info "$name" || true

  exit 1
}

launch_instance() {
  local name="$1"

  if multipass info "$name" >/dev/null 2>&1; then
    echo "$name already exists"

    multipass delete "$name" || true
    multipass purge || true
  fi

  multipass launch "$IMAGE" \
    --name "$name" \
    --cpus "$CPUS" \
    --memory "$MEMORY" \
    --disk "$DISK"

  wait_for_instance "$name"
}