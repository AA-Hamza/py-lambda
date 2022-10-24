CLOUD_FORMATION_FILE_NAME=cloudformation.yml
PARAMETERS_FILE_NAME=parameters.json
CLOUD_FORMATION_STACK_NAME=lambda
BUILD_DIR=build

## This needs to be updated from parameters.json
FUNCTION=py-lambda
FUNCTION_ZIP=$(BUILD_DIR)/$(FUNCTION).zip
S3_BUCKET=mylambdas

all: build

.PHONY: clean build upload

clean:
	rm -rf $(BUILD_DIR)

build: clean
	mkdir -p $(BUILD_DIR)/site-packages
	zip -r $(FUNCTION_ZIP) . -x "*.git*" "build*" "Makefile" "requirements.txt" "README.md"
	python3.9 -m venv $(BUILD_DIR)/$(FUNCTION)
	. $(BUILD_DIR)/$(FUNCTION)/bin/activate; \
	pip3 install -r requirements.txt; \
	cp -r $$VIRTUAL_ENV/lib/python3.9/site-packages/ build/site-packages
	cd build/site-packages; zip -g -r ../$(FUNCTION).zip . -x "*__pycache__*"

upload: build
	aws s3 cp $(FUNCTION_ZIP) s3://$(S3_BUCKET)/$(FUNCTION).zip
	echo "Use CFN stack to deploy Lambda from s3://$(S3_BUCKET)/$(FUNCTION).zip"

deploy: upload
	aws cloudformation create-stack --stack-name $(CLOUD_FORMATION_STACK_NAME) --template-body file://$(CLOUD_FORMATION_FILE_NAME) --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --parameters file://$(PARAMETERS_FILE_NAME)

	aws cloudformation wait stack-create-complete --stack-name $(CLOUD_FORMATION_STACK_NAME) 

update_stack: 
	aws cloudformation update-stack --stack-name $(CLOUD_FORMATION_STACK_NAME) --template-body file://$(CLOUD_FORMATION_FILE_NAME) --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --parameters file://$(PARAMETERS_FILE_NAME)

	aws cloudformation wait stack-update-complete --stack-name $(CLOUD_FORMATION_STACK_NAME) 
	
remove_lambda:
	aws cloudformation delete-stack --stack-name $(CLOUD_FORMATION_STACK_NAME) 

stack_logs:
	aws cloudformation describe-stack-events --stack-name $(CLOUD_FORMATION_STACK_NAME)
