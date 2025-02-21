#!/bin/bash

# Make the curl request and capture both output and error
output=$(curl -s --show-error --fail -X POST \
    -H "Content-Type: application/json" \
    -d '{
    "login": "EE30303039914",
    "password": "OK"
  }' \
    http://localhost:8080/auth/login 2>&1)
curl_status=$?

# Check if curl command succeeded
if [ $curl_status -ne 0 ]; then
    echo "Error: $output"
    exit 1
fi

# Check if output is valid JSON and extract response
if echo "$output" | jq . >/dev/null 2>&1; then
    response=$(echo "$output" | jq -r '.response')
else
    echo "Error: Invalid JSON response from server: $output"
    exit 1
fi

echo "$response"

# Copy to clipboard based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "$response" | pbcopy
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux (requires xclip or xsel)
    if command -v xclip >/dev/null 2>&1; then
        echo "$response" | xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        echo "$response" | xsel --clipboard
    else
        echo "Please install xclip or xsel to enable clipboard functionality"
        exit 0
    fi
fi

printf "\nToken has been copied to clipboard!"
