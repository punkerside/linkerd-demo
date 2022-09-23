SHELL  := /bin/bash

PROJECT = punkerside
ENV     = lab
SERVICE = linkerd

# iniciando cluster
minikube:
	@minikube start -p ${PROJECT}-${ENV}-${SERVICE} --driver=docker --kubernetes-version=v1.24.3

# liberando imagen de aplicacion de prueba
release:
ifndef DOCKER_USER
	$(error DOCKER_USER is undefined)
endif
ifndef DOCKER_PASS
	$(error DOCKER_PASS is undefined)
endif
	@docker build -t ${DOCKER_USER}/${PROJECT}-${ENV}-${SERVICE}:latest -f docker/Dockerfile .
	@docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}
	@docker push ${DOCKER_USER}/${PROJECT}-${ENV}-${SERVICE}:latest











deploy:
ifndef DOCKER_USER
	$(error DOCKER_USER is undefined)
endif
	@export DEPLOY_NAME=${SERVICE}-${ENV} DEPLOY_IMAGE=${DOCKER_USER}/${PROJECT}-${ENV}-${SERVICE}:latest && envsubst < kubernetes/deployment.yaml | kubectl apply -f -
	@export DEPLOY_NAME=${SERVICE}-${ENV} && envsubst < kubernetes/service.yaml | kubectl apply -f -

# service mesh
linkerd:
	@linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
	@linkerd check
	@linkerd viz install | kubectl apply -f -
	@linkerd check

mesh:
	@kubectl get deploy -o yaml | linkerd inject - | kubectl apply -f -

# destroy all resources
delete:
	@minikube delete -p ${PROJECT}-${ENV}-${SERVICE}