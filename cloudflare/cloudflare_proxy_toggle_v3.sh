#!/bin/bash

# Replace with your actual values
YOUR_API_KEY="YOUR_API_KEY"
YOUR_EMAIL="YOUR_EMAIL"
SLACK_WEBHOOK_URL="YOUR_SLACK_WEBHOOK_URL"

# Function to enable or disable proxy and send Slack notification
toggle_proxy() {
  local zone_identifier=$1
  local identifier=$2
  local proxy_set=$3
  local ttl_value=${4:-60}

  curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$identifier" \
    -H "X-Auth-Email: $YOUR_EMAIL" \
    -H "X-Auth-Key: $YOUR_API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"proxied\":$proxy_set, \"ttl\":$ttl_value}"

  # Send Slack notification
  if [ "$proxy_set" = true ]; then
    message=":white_check_mark: Proxy enabled for *$zone_identifier*, A record *$identifier*."
  else
    message=":x: Proxy disabled for *$zone_identifier*, A record *$identifier*."
  fi

  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" $SLACK_WEBHOOK_URL
}

# Disable proxy
toggle_proxy "zone_identifier_01" "a_record_id_01" false 60
toggle_proxy "zone_identifier_02" "a_record_id_02" false 60
toggle_proxy "zone_identifier_03" "a_record_id_03" false 60

# Sleep for 4 hours (14400 seconds)
sleep 14400

# Enable proxy
toggle_proxy "zone_identifier_01" "a_record_id_01" true
toggle_proxy "zone_identifier_02" "a_record_id_02" true
toggle_proxy "zone_identifier_03" "a_record_id_03" true