#!/bin/bash

set -eo pipefail

if [ -z "$DEMO_PASSWORD" ]; then
  echo "Warning: DEMO_PASSWORD environment variable is not set."
  exit 1
fi

export INGRESS_IP=$(kubectl describe svc contour-envoy --namespace projectcontour | grep Ingress | awk '{print $3}')
export TOKEN=$(curl "https://${INGRESS_IP}.nip.io/auth/realms/master/protocol/openid-connect/token" \
  -d "grant_type=password&client_id=admin-cli&username=admin&password=$DEMO_PASSWORD" \
  -k | jq '.access_token' | sed 's/^"\(.*\)"$/\1/')

curl -v https://${INGRESS_IP}.nip.io/auth/admin/realms/helix/users \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $TOKEN"   \
  --data '{"firstName":"xyz", "lastName":"xyz", "username":"xyz", "email":"xyz@example.com", "enabled":"true", "credentials": [{"type": "password","value": "'"$DEMO_PASSWORD"'","temporary": false}]}' \
  -k

