BUILD_DIR=build
WORKSPACE_NAME=src
WORKSPACE_DIR=$(BUILD_DIR)/$(WORKSPACE_NAME)

SRC_DIR=src
PRODUCT?=cfn_each

build:

	mkdir -p $(WORKSPACE_DIR)

	pip install -r requirements.txt -t $(WORKSPACE_DIR)

	cp *.py $(WORKSPACE_DIR)
	cd $(WORKSPACE_DIR) && zip --quiet --recurse-paths ../$(PRODUCT).zip *

clean:
	rm -rf build
