#!/bin/bash

# Based on https://bugbounty.info/Recon/Pipeline

DOMAIN=$1
OUTPUT_DIR="/recon/$DOMAIN"
TELEGRAM_NOTIFICATION_URL="https://api.telegram.org/bot$TELEGRAM_API_TOKEN/sendMessage"


mkdir -p "$OUTPUT_DIR/subs"

# Passive enumeration -- runs fast, no active connections
subfinder -d "$DOMAIN" -all -silent -o "$OUTPUT_DIR/subs/subfinder.txt" &
amass enum -passive -d "$DOMAIN" -o "$OUTPUT_DIR/subs/amass.txt" &
assetfinder --subs-only "$DOMAIN" > "$OUTPUT_DIR/subs/assetfinder.txt" &
findomain --target "$DOMAIN" --quiet -u "$OUTPUT_DIR/subs/findomain.txt" &

# Certificate transparency
curl -s "https://crt.sh/?q=%.${DOMAIN}&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > "$OUTPUT_DIR/subs/crtsh.txt" &
wait
 
# Merge and deduplicate
cat "$OUTPUT_DIR/subs/"*.txt | sort -u > "$OUTPUT_DIR/subs/all_subs.txt"
wc -l "$OUTPUT_DIR/subs/all_subs.txt"

# Compare the quick subdomain list to yesterday's
comm -23 \
  <(sort "$OUTPUT_DIR/subs/live_subs.txt") \
  <(sort "$OUTPUT_DIR/subs/live_subs_yesterday.txt") \
  > "$OUTPUT_DIR/new_subs_today.txt"
 
if [ -s "$OUTPUT_DIR/new_subs_today.txt" ]; then
  # Notify via Slack webhook
  NEW_COUNT=$(wc -l < "$OUTPUT_DIR/new_subs_today.txt")
  NEW_SUBS=$(cat "$OUTPUT_DIR/new_subs_today.txt" | head -10 | tr '\n' ', ')
  curl -s -X POST "$TELEGRAM_NOTIFICATION_URL" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\": \"$TELEGRAM_CHAT_ID\", \"text\": \"[$DOMAIN] $NEW_COUNT new subdomains: $NEW_SUBS\"}"
fi