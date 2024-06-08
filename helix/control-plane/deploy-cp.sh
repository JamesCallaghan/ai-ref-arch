#!/bin/bash

set -eo pipefail

if [ -z "$DEMO_PASSWORD" ]; then
  echo "Warning: DEMO_PASSWORD environment variable is not set."
  exit 1
fi

export INGRESS_IP=$(kubectl describe svc contour-envoy --namespace projectcontour | grep Ingress | awk '{print $3}')

envsubst < cp-values.yaml > cp-substituted-values.yaml

${HELM} repo add helix https://charts.helix.ml
${HELM} repo update
${HELM} upgrade --install helix helix/helix-controlplane -f values.yaml -f cp-substituted-values.yaml

rm cp-substituted-values.yaml