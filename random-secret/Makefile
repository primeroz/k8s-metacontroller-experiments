PWD := ${CURDIR}
ADDITIONAL_BUILD_ARGUMENTS?=""

PKG		:= metacontroller
API_GROUPS := metacontroller/v1alpha1

CODE_GENERATOR_VERSION="v0.24.3"

# TODO pass as args
imageTag = 0.1
jsonnetdTag = 0.5

all: generate_crds

.PHONY: generate_crds
generate_crds:
	@echo "+ Generating crds"
	@go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.12.0
	@controller-gen rbac:roleName=manager-role +crd:generateEmbeddedObjectMeta=true +paths="./api/..." +output:crd:stdout > v1/crdv1.yaml

.PHONY: apply_manifests
apply_manifests:
	@kubectl apply -k .

image:
	docker build -t primeroz/jsonnetd-random-secrets-controller:$(imageTag) .

push: image
	docker push primeroz/jsonnetd-random-secrets-controller:$(imageTag)
