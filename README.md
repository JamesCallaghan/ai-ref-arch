# ai-ref-arch

## Prerequisites

To stand up the infrastructure for this demo, you need gcloud CLI access to a GCP project:

```bash
gcloud auth application-default login.
```

Passwords for several services will need to be set up. For simplicity, we have used the same password across all services. You will need to set the `DEMO_PASSWORD` environment variable to something of your choice:

```bash
export DEMO_PASSWORD=<your password here>
```

This demo uses the following client tools:

- terraform
- kubectl
- helm
- jq
- envsubst
- gcloud CLI
- curl

## Run the demo

Spin up a GKE cluster with Contour for Ingress, cert-manager to provide self-signed certificates for demo purposes, keycloak, the Helix ML control plane, and one Helix runner. This will take several minutes:

```bash
make all-up
```

To avoid the need to create DNS records just for our demo, we will use `nip.io` to access Helix from outside the cluster. Find the Contour LoadBalancer IP with the following command:

```bash
kubectl describe svc contour-envoy --namespace projectcontour | grep Ingress | awk '{print $3}'
```

The Helix UI will be available at `https://<IP from the above command>.nip.io`

You will be able to log in with the email `xyz@example.com` and the `DEMO_PASSWORD` you chose at the start.

Please note that the runner may take several minutes to be ready.

## Testing

```bash
make test
```

Note that the test may fail the first time. Inspecting the runner logs may show `Pulling model llama3:instruct`. Once this is complete, the test should pass.

## Teardown

```bash
make delete-all
```
