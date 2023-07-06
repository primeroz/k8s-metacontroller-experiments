PWD := ${CURDIR}

imageTag = 0.4
jsonnetdTag = 0.6

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
	docker build -t primeroz/jsonnetd-random-secrets-controller:$(imageTag) --build-arg jsonnetdTag=$(jsonnetdTag) .

push: image
	docker push primeroz/jsonnetd-random-secrets-controller:$(imageTag)
	kustomize edit set image primeroz/jsonnetd-random-secrets-controller:$(imageTag)
