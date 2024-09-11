#!/bin/bash

# Replace with your actual values
YOUR_API_KEY="YOUR_API_KEY"
YOUR_EMAIL="YOUR_EMAIL"
zone_identifier="zone_identifier"
identifier="a_recode_identifier"
ttl_value="60"  # TTL in seconds

# Function to enable or disable proxy
toggle_proxy() {
  local proxy_set=$1

  curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$identifier" \
    -H "X-Auth-Email: $YOUR_EMAIL" \
    -H "X-Auth-Key: $YOUR_API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"proxied\":$proxy_set, \"ttl\":$ttl_value}"
}

# Enable proxy
echo "Enabling proxy..."
toggle_proxy true

# Sleep for 4 hours (14400 seconds)
echo "Sleeping for 4 hours..."
sleep 14400

# Disable proxy
echo "Disabling proxy..."
toggle_proxy false

echo "Script completed."