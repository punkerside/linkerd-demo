PROJECT = punkerside
ENV     = lab
SERVICE = linkerd

init:
	@cd terraform/ && terraform init

apply:
	@cd terraform/ && terraform apply -var="name=${PROJECT}-${ENV}" -auto-approve

destroy:
	@cd terraform/ && terraform destroy -var="name=${PROJECT}-${ENV}" -auto-approve