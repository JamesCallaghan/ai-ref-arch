#!/usr/bin/env bats

if [ -z "$DEMO_PASSWORD" ]; then
  echo "Warning: DEMO_PASSWORD environment variable is not set."
  exit 1
fi

@test "Check that LLM responds Hello" {
  export USERNAME=xyz@example.com

  export INGRESS_IP=$(kubectl describe svc contour-envoy --namespace projectcontour | grep Ingress | awk '{print $3}')

  TOKEN=$(curl "https://${INGRESS_IP}.nip.io/auth/realms/helix/protocol/openid-connect/token" \
    -d "grant_type=password&client_id=admin-cli&username=$USERNAME&password=$DEMO_PASSWORD" \
    -k | jq '.access_token' | sed 's/^"\(.*\)"$/\1/')

  SESSION_ID=$(curl "https://${INGRESS_IP}.nip.io/api/v1/sessions" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: multipart/form-data; boundary=---BOUNDARY' \
    --data-binary @session-data.form \
    --compressed -k | jq '.id' | sed 's/^"\(.*\)"$/\1/')

  sleep 10

  ANSWER=$(curl "https://${INGRESS_IP}.nip.io/api/v1/sessions/$SESSION_ID" \
    -H "Authorization: Bearer $TOKEN" --compressed -k | jq '.interactions[1].message' | sed 's/^"\(.*\)"$/\1/')

   echo $ANSWER | grep Hello

}