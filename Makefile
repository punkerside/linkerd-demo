SHELL  := /bin/bash

PROJECT            = punkerside
ENV                = lab
SERVICE            = linkerd
AWS_DEFAULT_REGION = us-east-1
K8S_VERSION        = 1.23

# creando cluster k8s
cluster:
	@cd terraform/ && \
	  terraform init
	@export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} && cd terraform/ && terraform apply \
	  -var="project=${PROJECT}" \
	  -var="env=${ENV}" \
	  -var="service=${SERVICE}" \
	  -var="k8s_version=${K8S_VERSION}" -auto-approve
	@rm -rf ~/.kube/
	@aws eks update-kubeconfig --name ${PROJECT}-${ENV}-${SERVICE} --region ${AWS_DEFAULT_REGION}

# liberando imagen de prueba
release:
	@docker build -t $(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PROJECT}-${ENV}-${SERVICE}:latest -f docker/Dockerfile .
	@aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin $(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
	@docker push $(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PROJECT}-${ENV}-${SERVICE}:latest

# desplegar aplicacion de prueba
deploy:
	@helm repo add chart-service https://punkerside.github.io/chart-service/charts
	@helm repo update
	@helm upgrade -i service-a chart-service/service \
	  --set name=service-a \
	  --set spec.containers.containerPort=5000 \
	  --set spec.containers.probe=/status \
	  --set spec.containers.periodSeconds=45 \
	  --set spec.containers.image=$(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PROJECT}-${ENV}-${SERVICE}:latest
	@helm upgrade -i service-b chart-service/service \
	  --set name=service-b \
	  --set spec.containers.containerPort=5000 \
	  --set spec.containers.probe=/status \
	  --set spec.containers.periodSeconds=45 \
	  --set spec.containers.image=$(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PROJECT}-${ENV}-${SERVICE}:latest
	@helm upgrade -i service-c chart-service/service \
	  --set name=service-c \
	  --set spec.containers.containerPort=5000 \
	  --set spec.containers.probe=/status \
	  --set spec.containers.periodSeconds=45 \
	  --set spec.containers.image=$(shell aws sts get-caller-identity | jq -r .Account).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PROJECT}-${ENV}-${SERVICE}:latest

# service mesh
linkerd:
	@linkerd install --crds | kubectl apply -f -
	@linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
	@linkerd check

# service mesh dashboard
linkerd-viz:
	@linkerd viz install | kubectl apply -f -
	@linkerd check

# agregando malla de servicio a la aplicacion de prueba
inject:
	@kubectl get deploy -o yaml | linkerd inject - | kubectl apply -f -
	@kubectl rollout restart deploy

# eliminando todos los recursos
destroy:
	@export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} && cd terraform/ && terraform destroy \
	  -var="project=${PROJECT}" \
	  -var="env=${ENV}" \
	  -var="service=${SERVICE}" \
	  -var="k8s_version=${K8S_VERSION}" -auto-approve