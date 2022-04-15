PROJECT = punkerside
ENV     = lab
SERVICE = linkerd

DOCKER_UID  = $(shell id -u)
DOCKER_GID  = $(shell id -g)
DOCKER_USER = $(shell whoami)

apply:
	@cd terraform/ && terraform init
	@cd terraform/ && terraform apply -var="name=${PROJECT}-${ENV}" -auto-approve

destroy:
	@cd terraform/ && terraform destroy -var="name=${PROJECT}-${ENV}" -auto-approve

release:
	@docker build -t ${PROJECT}-${ENV}-${SERVICE}:release -f docker/Dockerfile .

init:
	export IMAGE=${PROJECT}-${ENV}-${SERVICE}:release && \
	docker-compose -p ${PROJECT}_${ENV}_${SERVICE} up -d

stop:
	export IMAGE=${PROJECT}-${ENV}-${SERVICE}:release && \
	docker-compose -p ${PROJECT}_${ENV}_${SERVICE} down

restart:
	make stop
	make init