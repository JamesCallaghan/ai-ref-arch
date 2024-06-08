#!/bin/bash

set -eo pipefail

if [ -z "$DEMO_PASSWORD" ]; then
  echo "Warning: DEMO_PASSWORD environment variable is not set."
  exit 1
fi

export INGRESS_IP=$(kubectl describe svc contour-envoy --namespace projectcontour | grep Ingress | awk '{print $3}')

envsubst < keycloak-values.yaml > keycloak-substituted-values.yaml

${HELM} upgrade --install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
  -f keycloak-substituted-values.yaml

rm keycloak-substituted-values.yaml