#!/bin/bash

# Based on https://bugbounty.info/Recon/Pipeline

source "../.env"

DOMAIN=$1
OUTPUT_DIR="/recon/$DOMAIN"
WORDLISTS_DIR="$HOME/wordlists"
TELEGRAM_NOTIFICATION_URL="https://api.telegram.org/bot$TELEGRAM_API_TOKEN/sendMessage"

RAFT_LARGE_WORDLIST = "$WORDLISTS_DIR/raft-larghttps://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/Web-Content/raft-large-words.txte-words.txt"


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

# massdns for fast bulk resolution
massdns -r resolvers.txt -t A -o S "$OUTPUT_DIR/subs/all_subs.txt" > "$OUTPUT_DIR/subs/resolved.txt"
 
# Extract just the live hostnames
grep " A " "$OUTPUT_DIR/subs/resolved.txt" | awk '{print $1}' | sed 's/\.$//' | sort -u > "$OUTPUT_DIR/subs/live_subs.txt"
 
# puredns as an alternative (handles wildcard filtering)
puredns resolve "$OUTPUT_DIR/subs/all_subs.txt" -r resolvers.txt -w "$OUTPUT_DIR/subs/live_subs.txt"

# httpx probes multiple ports by default and returns rich metadata
httpx -l "$OUTPUT_DIR/subs/live_subs.txt" \
  -ports 80,443,8080,8443,8888,3000,4000,5000,9000 \
  -title -tech-detect -status-code -content-length \
  -json -o "$OUTPUT_DIR/http_probe.json"
 
# Extract just URLs for downstream tools
cat "$OUTPUT_DIR/http_probe.json" | jq -r '.url' | sort -u > "$OUTPUT_DIR/live_urls.txt"

# Get IPs from resolved subdomains
grep " A " "$OUTPUT_DIR/subs/resolved.txt" | awk '{print $3}' | sort -u > "$OUTPUT_DIR/ips.txt"
 
# Fast scan with masscan first (requires root or cap_net_raw)
masscan -iL "$OUTPUT_DIR/ips.txt" \
  -p1-65535 --rate=10000 \
  -oJ "$OUTPUT_DIR/masscan.json"
 
# Targeted nmap on open ports for service detection
# Parse masscan output to get host:port pairs
python3 parse_masscan.py "$OUTPUT_DIR/masscan.json" | xargs -I{} nmap -sV -p {} --open -oA "$OUTPUT_DIR/nmap_{}" {}

# ffuf with a good wordlist
cat "$OUTPUT_DIR/live_urls.txt" | while read url; do
    domain=$(echo "$url" | sed 's|https\?://||' | cut -d/ -f1 | tr ':' '_')
    ffuf -w $RAFT_LARGE_WORDLIST \
      -u "${url}/FUZZ" \
      -mc 200,201,204,301,302,307,401,403 \
      -ac \
      -t 50 \
      -o "$OUTPUT_DIR/content/$domain.json" \
      -of json \
      2>/dev/null &
done
wait

# Collect JS URLs
cat "$OUTPUT_DIR/live_urls.txt" | \
  xargs -P10 -I{} sh -c "gau {} && waybackurls {}" | \
  grep "\.js$" | sort -u \
  > "$OUTPUT_DIR/js_urls.txt"
 
# Download and analyze with LinkFinder + secretfinder
cat "$OUTPUT_DIR/js_urls.txt" | while read jsurl; do
    curl -sk "$jsurl" >> "$OUTPUT_DIR/all_js_combined.txt"
done
 
# Extract endpoints
python3 /opt/LinkFinder/linkfinder.py \
  -i "$OUTPUT_DIR/all_js_combined.txt" \
  -o cli > "$OUTPUT_DIR/js_endpoints.txt"
 
# Extract secrets
trufflehog filesystem "$OUTPUT_DIR/all_js_combined.txt" --only-verified > "$OUTPUT_DIR/js_secrets.txt"

# Compare today's subdomain list to yesterday's
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
 
# Roll files
cp "$OUTPUT_DIR/subs/live_subs.txt" "$OUTPUT_DIR/subs/live_subs_yesterday.txt"