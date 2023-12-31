SHELL=/bin/bash
JSONNET_FMT=--indent 2 --string-style s --comment-style s --no-pad-arrays --pad-objects --pretty-field-names

TEST_JSONNET=$(wildcard ./tests/*.jsonnet)
CODE_JSONNET=$(wildcard ./jsonnet/*.jsonnet)

ALL_JSONNET=$(TEST_JSONNET) $(CODE_JSONNET)

PHONY_GOLDEN=$(patsubst %.jsonnet,%-golden.json,$(TEST_JSONNET))
PHONY_PRINT_GOLDEN=$(patsubst %.jsonnet,%-print.yaml,$(TEST_JSONNET))
PHONY_DIFF=$(patsubst %.jsonnet,%.diff,$(TEST_JSONNET))
PHONY_PARSE=$(patsubst %.jsonnet,%.parse,$(ALL_JSONNET))


PWD := ${CURDIR}

imageTag = v0.51

all: generate_crds

.PHONY: generate_crds
generate_crds:
	@echo "+ Generating crds"
	@go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.12.0
	@controller-gen rbac:roleName=manager-role +crd:generateEmbeddedObjectMeta=true +paths="./api/..." +output:crd:stdout > v1/crdv1.yaml

.PHONY: apply_manifests
apply_manifests:
	@kubectl apply -k .

image_controller:
	docker build -t primeroz/jsonnetd-mqtt-controller:$(imageTag) .

push_controller: image_controller
	docker push primeroz/jsonnetd-mqtt-controller:$(imageTag)
	kustomize edit set image primeroz/jsonnetd-mqtt-controller:$(imageTag)


push: push_controller

test: lint parse diff

.PHONY: unittests lint diff %.parse %.diff %-golden.json %-print.yaml diff-help fix-lint print-golden gen-golden regen-golden delete-golden

lint:
	@set -e; errs=0; \
     for f in $(ALL_JSONNET) $(LIB_JSONNET); do \
   JSONNETFMTCMD=$$(command -v jsonnetfmt || echo "jsonnet fmt"); \
     if ! $$JSONNETFMTCMD --test $(JSONNET_FMT) -- $$f; then \
      echo "FAILED lint: $$f" >&2; \
      errs=$$(( $$errs + 1 )); \
    fi; \
  done; \
  if [ $$errs -gt 0 ]; then \
    echo "NOTE: if the 'lint' target fails, run:"; \
    echo "      $(MAKE) fix-lint lint"; \
    exit 1; \
  fi

diff: diff-help $(PHONY_DIFF)

%.diff: %.jsonnet
	diff -u $(*)-golden.json <(jsonnet $(<))

%.parse: %.jsonnet
	jsonnet $(<) > /dev/null

%-golden.json: %.jsonnet
	kubecfg --alpha -o json eval jsonnet/$(notdir $(<)) --tla-code-file request=tests/$(notdir $(<)) > $(@)

%-print.yaml: %.jsonnet
	@printf "\n#######################\n\n"
	kubecfg --alpha -o yaml eval jsonnet/$(notdir $(<)) --tla-code-file request=tests/$(notdir $(<))

diff-help:
	@echo "NOTE: if the 'diff' target fails, review output and run:"
	@echo "      $(MAKE) gen-golden diff"
	@echo

fix-lint:
	@set -e; \
	for f in $(ALL_JSONNET) $(LIB_JSONNET); do \
	JSONNETFMTCMD=$$(command -v jsonnetfmt || echo "jsonnet fmt"); \
	  echo $$JSONNETFMTCMD -i $(JSONNET_FMT) -- $$f; \
	  jsonnetfmt -i $(JSONNET_FMT) -- $$f; \
	done

print-golden: $(PHONY_PRINT_GOLDEN)

gen-golden: $(PHONY_GOLDEN)

regen-golden: delete-golden gen-golden

delete-golden:
	@find . -name "*-golden.json" -delete
