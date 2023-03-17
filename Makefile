init:
	terraform init

plan:
	terraform plan -out tfplan -var-file="vars.tfvars"

apply:
	terraform apply "tfplan"

go:
	terraform apply -var-file="vars.tfvars"

show:
	terraform show "tfplan"

destroy:
	terraform apply -destroy -var-file="vars.tfvars"

show_json:
	terraform show -json tf.plan | jq '.' > tf.json

show_plus:
	@terraform show "tfplan" | sed -r 's/'$(echo -e "\033")'\[[0-9]{1,2}(;([0-9]{1,2})?)?[mK]//g' | > tfplan.md

clear_state:
	rm .terraform.lock.hcl
	rm terraform.tfstate
	rm terraform.tfstate.backup


.PHONY: init plan apply show destroy show_json show_plus clear_state docs
