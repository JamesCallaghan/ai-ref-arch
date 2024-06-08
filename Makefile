NETWORK_NAME ?= helix
CLUSTER_NAME ?= helix-gpu-cluster
REGION ?= europe-west2
LOCATION ?= europe-west2-a
NODE_POOL_NAME ?= gpu-node-pool
GPU_TYPE ?= nvidia-l4
HELM_VERSION ?= 3.15.0
TERRAFORM_VERSION ?= 1.8.3

PROJECT_ID := $(shell gcloud config get-value project)

.EXPORT_ALL_VARIABLES:

.PHONY: terraform-apply
terraform_apply: terraform
	cd infra && \
		$(TERRAFORM) init && \
		$(TERRAFORM) apply \
		-var project_id=$(PROJECT_ID) \
		-var network_name=$(NETWORK_NAME) \
		-var cluster_name=$(CLUSTER_NAME) \
		-var node_pool_name=$(NODE_POOL_NAME) \
		-var region=$(REGION) \
		-var location=$(LOCATION)

.PHONY: kubecontext
kubecontext:
	gcloud container clusters get-credentials $(CLUSTER_NAME) \
    --region=$(LOCATION)

.PHONY: contour
contour: kubecontext helm
	$(HELM) install contour bitnami/contour --namespace projectcontour --create-namespace
	kubectl -n projectcontour wait --timeout=180s --for=condition=Ready pod -l app.kubernetes.io/component=contour
	kubectl -n projectcontour wait --timeout=180s --for=condition=Ready pod -l app.kubernetes.io/component=envoy

.PHONY: cert-manager
cert-manager: kubecontext helm
	$(HELM) install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.5 \
  --set installCRDs=true

	kubectl -n cert-manager wait --timeout=180s --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager
	
	kubectl apply -f infra/cert-manager/issuer.yaml

.PHONY: keycloak
keycloak: kubecontext helm
	cd infra/keycloak && ./deploy-keycloak.sh
	kubectl wait --timeout=240s --for=condition=Ready pod -l app.kubernetes.io/component=keycloak

.PHONY: helix-cp
helix-cp: kubecontext helm
	cd helix/control-plane && ./deploy-cp.sh
	kubectl wait --timeout=300s --for=condition=Ready pod -l app.kubernetes.io/component=controlplane
	./create-helix-user.sh

.PHONY: helix-user
helix-user: kubecontext
	cd helix/control-plane && ./create-helix-user.sh

.PHONY: runner
runner: kubecontext helm
	cd helix/helix-runner && ./create-runner.sh

.PHONY: test
test: kubecontext
	cd tests && bats hello-test.bats

.PHONY: delete-all
delete-all: terraform
	cd infra && \
		$(TERRAFORM) destroy \
		-var project_id=$(PROJECT_ID) \
		-var network_name=$(NETWORK_NAME) \
		-var cluster_name=$(CLUSTER_NAME) \
		-var node_pool_name=$(NODE_POOL_NAME) \
		-var region=$(REGION) \
		-var location=$(LOCATION) \
		-auto-approve

.PHONY: all-up
all-up: terraform_apply contour cert-manager keycloak helix-cp helix-user runner

.PHONY: helm
HELM = $(shell pwd)/bin/helm
helm: ## Download helm if required
ifeq (,$(wildcard $(HELM)))
ifeq (,$(shell which helm 2> /dev/null))
	@{ \
		mkdir -p $(dir $(HELM)); \
		curl -sSLo $(HELM).tar.gz https://get.helm.sh/helm-v$(HELM_VERSION)-$(OS)-$(ARCH).tar.gz; \
		tar -xzf $(HELM).tar.gz --one-top-level=$(dir $(HELM)) --strip-components=1; \
		chmod + $(HELM); \
	}
else
HELM = $(shell which helm)
endif
endif

.PHONY: terraform
TERRAFORM = $(shell pwd)/bin/terraform
terraform: ## Download terraform if required
ifeq (,$(wildcard $(TERRAFORM)))
ifeq (,$(shell which terraform 2> /dev/null))
	@{ \
		mkdir -p $(dir $(TERRAFORM)); \
		curl -sSLo $(TERRAFORM).tar.gz https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_$(OS)_$(ARCH).zip; \
		unzip $(TERRAFORM).tar.gz; \
		mv terraform $(dir $(TERRAFORM)); \
		chmod + $(TERRAFORM); \
	}
else
TERRAFORM = $(shell which terraform)
endif
endif