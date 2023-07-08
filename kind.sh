#!/bin/sh
#
# Helper script to start KinD
#
# Also adds a docker-registry and an ingress to aid local development
#
# See https://kind.sigs.k8s.io/docs/user/quick-start/ 
#
set -o errexit

[ "$TRACE" ] && set -x

VERBOSE=1
[ "$TRACE" ] && VERBOSE=3

source ./common


KIND_K8S_IMAGE=${KIND_K8S_IMAGE:-"kindest/node:v1.26.6@sha256:6e2d8b28a5b601defe327b98bd1c2d1930b49e5d8c512e1895099e4504007adb"}
KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-"meta"}
KIND_WAIT=${KIND_WAIT:-"120s"}
KIND_API_SERVER_ADDRESS=${KIND_API_SERVER_ADDRESS:-"0.0.0.0"}
KIND_API_SERVER_PORT=${KIND_API_SERVER_PORT:-6443}

## Create a cluster with the local registry enabled in container
create() {

e_header "Creating KIND Cluster"

cat <<EOF | kind create -v ${VERBOSE}  cluster --name="${KIND_CLUSTER_NAME}" --image="${KIND_K8S_IMAGE}" --wait="${KIND_WAIT}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: ${KIND_API_SERVER_ADDRESS}
  apiServerPort: ${KIND_API_SERVER_PORT}

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  - |
    kind: ClusterConfiguration
    networking:
      dnsDomain: cluster.local
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

e_success "Done"

e_header "Creating Contour Gateway API"
# Add  Contour Gateway API 
kubectl apply -f "https://projectcontour.io/quickstart/contour-gateway-provisioner.yaml"
kubectl wait --namespace projectcontour \
  --for=condition=available \
  --timeout=90s \
  deploy/contour-gateway-provisioner

kubectl wait --namespace gateway-system \
  --for=condition=available \
  --timeout=90s \
  deploy/gateway-api-admission-server

# Wait for cert patching of validating webhook to happen
kubectl wait --namespace gateway-system --timeout=60s --for=condition=complete job gateway-api-admission
kubectl wait --namespace gateway-system --timeout=60s --for=condition=complete job gateway-api-admission-patch

kubectl apply -f - <<EOF
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF

kubectl apply -f - <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: contour
  namespace: projectcontour
spec:
  gatewayClassName: contour
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
EOF

kubectl wait --namespace projectcontour \
  --for=condition=programmed \
  --timeout=90s \
  gateway/contour

kubectl wait --namespace projectcontour \
  --for=condition=available \
  --timeout=180s \
  deploy/contour-contour

kubectl rollout status --namespace projectcontour \
  --timeout=300s \
  daemonset/envoy-contour

e_success "Done"

}

## Delete the cluster
delete() {
  kind delete cluster --name "${KIND_CLUSTER_NAME}"
}

## Check if the cluster exists
exists() {
  set +e
  kind get clusters | egrep "${KIND_CLUSTER_NAME}" 2>/dev/null >/dev/null
  exit $rc
  set -e
}

## Display usage
usage()
{
    echo "usage: $0 [create|delete|exists]"
}

## Argument parsing
if [ "$#" = "0" ]; then
  usage
  exit 1
fi
    
while [ "$1" != "" ]; do
    case $1 in
        create )                create
                                ;;
        delete )                delete
                                ;;
        exists )                exists
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
