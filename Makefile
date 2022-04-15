PROJECT = punkerside
ENV     = lab
SERVICE = linkerd

DOCKER_UID  = $(shell id -u)
DOCKER_GID  = $(shell id -g)
DOCKER_USER = $(shell whoami)

DOCKER_HUB_USER = punkerside
DOCKER_HUB_PASS = pass

apply:
	@cd terraform/ && terraform init
	@cd terraform/ && terraform apply -var="name=${PROJECT}-${ENV}" -auto-approve

destroy:
	@cd terraform/ && terraform destroy -var="name=${PROJECT}-${ENV}" -auto-approve

release:
	@docker build -t punkerside/${PROJECT}-${ENV}-${SERVICE}:latest -f docker/Dockerfile .
	@docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASS}
	@docker push punkerside/${PROJECT}-${ENV}-${SERVICE}:latest

init:
	export IMAGE=${PROJECT}-${ENV}-${SERVICE}:release && \
	docker-compose -p ${PROJECT}_${ENV}_${SERVICE} up -d

stop:
	export IMAGE=${PROJECT}-${ENV}-${SERVICE}:release && \
	docker-compose -p ${PROJECT}_${ENV}_${SERVICE} down

restart:
	make stop
	make init

deploy:
	export DEPLOY_NAME=${SERVICE}-${ENV} DEPLOY_IMAGE=punkerside/${PROJECT}-${ENV}-${SERVICE}:latest && envsubst < kubernetes/deployment.yaml | kubectl apply -f -
	export DEPLOY_NAME=${SERVICE}-${ENV} && envsubst < kubernetes/service.yaml | kubectl apply -f -

delete:
	export DEPLOY_NAME=${SERVICE}-${ENV} DEPLOY_IMAGE=punkerside/${PROJECT}-${ENV}-${SERVICE}:latest && envsubst < kubernetes/deployment.yaml | kubectl delete -f -
	export DEPLOY_NAME=${SERVICE}-${ENV} && envsubst < kubernetes/service.yaml | kubectl delete -f -