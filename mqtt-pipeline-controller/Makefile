PWD := ${CURDIR}

imageTag = 0.1
mqttTag = 0.1
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

image_controller:
	docker build -t primeroz/jsonnetd-mqtt-controller:$(imageTag) --build-arg jsonnetdTag=$(jsonnetdTag) .

push_controller: image_controller
	docker push primeroz/jsonnetd-mqtt-controller:$(imageTag)
	kustomize edit set image primeroz/jsonnetd-mqtt-controller:$(imageTag)

image_mqtt_publisher:
	docker build -f Dockerfile.mqtt_publisher -t primeroz/mqtt-publisher:$(mqttTag) .
push_mqtt_publisher: image_mqtt_publisher
	docker push primeroz/mqtt-publisher:$(mqttTag)

image_mqtt_subscriber:
	docker build -f Dockerfile.mqtt_subscriber -t primeroz/mqtt-subscriber:$(mqttTag) .
push_mqtt_subscriber: image_mqtt_subscriber
	docker push primeroz/mqtt-subscriber:$(mqttTag)


push: push_controller push_mqtt_publisher push_mqtt_subscriber
