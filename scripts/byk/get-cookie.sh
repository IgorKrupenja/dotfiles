#!/bin/bash

# Make the curl request and extract only the "response" value using jq
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{
    "login": "EE30303039914",
    "password": "OK"
  }' \
    http://localhost:8080/auth/login | jq -r '.response')

# Print the response
echo "$response"

# Copy the response to clipboard
echo "$response" | pbcopy

echo "Token has been copied to clipboard!"
