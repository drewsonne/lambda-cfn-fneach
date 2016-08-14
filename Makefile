BUILD_DIR=build
WORKSPACE_NAME=src
WORKSPACE_DIR=$(BUILD_DIR)/$(WORKSPACE_NAME)

SRC_DIR=src
PRODUCT?=cfn_each
KEY?=$(PRODUCT).zip
PROFILE?=default
REGION?=us-east-1

ENVS=AWS_DEFAULT_PROFILE=$(PROFILE) AWS_DEFAULT_REGION=$(REGION)

build:

	mkdir -p $(WORKSPACE_DIR)

	pip install -r requirements.txt -t $(WORKSPACE_DIR)

	cp *.py $(WORKSPACE_DIR)
	cd $(WORKSPACE_DIR) && zip --quiet --recurse-paths ../$(PRODUCT).zip *

install: build
	$(ENVS) aws s3 cp build/$(PRODUCT).zip s3://$(BUCKET)/$(KEY)

	$(ENVS) aws cloudformation create-stack \
		--template-body file://$(CURDIR)/custom_cfneach.json \
		--stack-name CFNEach \
		--capabilities CAPABILITY_IAM \
		--parameters \
			ParameterKey=CfnEachS3Bucket,ParameterValue=$(BUCKET),UsePreviousValue=false \
			ParameterKey=CfnEachS3Key,ParameterValue=$(KEY),UsePreviousValue=false

	$(ENVS) aws cloudformation wait stack-create-complete --stack-name CFNEach

demo:
	$(ENVS) aws cloudformation create-stack \
		--template-body file://$(CURDIR)/demo_cfneach.json \
		--stack-name CFNDemo \
		--parameters \
			ParameterKey=BucketName,ParameterValue=DemoBucketName,UsePreviousValue=false \
			ParameterKey=AccountIds,ParameterValue='0123456789012\,1234567890123\,2345678901234\,3456789012345',UsePreviousValue=false

	$(ENVS) aws cloudformation wait stack-create-complete --stack-name CFNDemo
	$(ENVS) aws cloudformation describe-stacks --stack-name CFNDemo

clean:
	$(RM) -r build

