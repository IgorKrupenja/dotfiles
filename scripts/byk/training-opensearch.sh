#!/bin/bash

CURRENT_DIR=$(pwd)

# Check if we're somewhere in a Training-Module directory
if [[ $(pwd) != *"Training-Module"* ]]; then
    echo "Error: This script must be run from within a Training-Module directory"
    exit 1
fi

# Find the root Training-Module directory by traversing up
while [[ $(pwd) != "/" && $(basename "$(pwd)") != "Training-Module" ]]; do
    cd ..
done

if [[ $(basename "$(pwd)") != "Training-Module" ]]; then
    echo "Error: Could not find Training-Module root directory"
    cd "$CURRENT_DIR" || exit
fi

echo "Found Training-Module root directory: $(pwd)"

echo "Initializing OpenSearch..."
cd DSL/OpenSearch || exit
./deploy-opensearch.sh http://localhost:9200 admin:admin true

echo "Populating OpenSearch with Rasa YAML files..."
cd ../Pipelines || exit
./init_with_mocks.sh http://localhost:3010

cd "$CURRENT_DIR" || exit

echo "Setup completed successfully!"
