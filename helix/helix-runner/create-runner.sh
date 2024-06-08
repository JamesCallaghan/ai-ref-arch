#!/bin/bash

set -eo pipefail

if [ -z "$DEMO_PASSWORD" ]; then
  echo "Warning: DEMO_PASSWORD environment variable is not set."
  exit 1
fi

envsubst < runner-values.yaml > runner-values-substituted.yaml

${HELM} upgrade --install helix-runner \
  ./ -f values.yaml \
  -f runner-values-substituted.yaml

rm runner-values-substituted.yaml