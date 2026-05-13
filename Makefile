.PHONY: build plan deploy destroy clean invoke-test

TF_DIR := terraform

build:
	@bash scripts/build.sh

plan: build
	terraform -chdir=$(TF_DIR) init -upgrade -reconfigure
	terraform -chdir=$(TF_DIR) plan

deploy: build
	terraform -chdir=$(TF_DIR) init -upgrade -reconfigure
	terraform -chdir=$(TF_DIR) apply -auto-approve

destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve

clean:
	rm -rf dist/

# Manually invoke the Lambda with a test event (requires AWS CLI)
invoke-test:
	aws lambda invoke \
		--function-name $$(terraform -chdir=$(TF_DIR) output -raw lambda_function_name) \
		--payload '{"source":"manual.test","detail-type":"Manual Test Event","detail":{"reason":"manual invocation test"}}' \
		--cli-binary-format raw-in-base64-out \
		/tmp/lambda-response.json && cat /tmp/lambda-response.json
