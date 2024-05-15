#!/bin/bash

# --- ip_comparison_checker.sh ---

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Functions ---

# Function to obtain public IP address
get_public_ip() {
  local ip=$(curl -s https://ipinfo.io/ip)
  if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid IP address received: $ip" >&2
    return 1
  fi
  echo "$ip"
}

# Function to obtain information from a specific database
get_info_from_db() {
  local ip="$1"
  local database="$2"

  # Sanitize IP address (remove any leading/trailing whitespace)
  ip=$(echo "$ip" | tr -d ' ')

  case "$database" in
    "whois")
      whois "$ip" | grep -iE 'origin|netname|country|stateprov|city'
      ;;
    "ipinfo.io")
      curl -s "https://ipinfo.io/$ip" | jq -r '.org, .country, .region, .city, .asn' 2>/dev/null
      ;;
    "ipapi.co")
      curl -s "https://ipapi.co/$ip/json/" | jq -r '.asn, .country_name, .region, .city' 2>/dev/null
      ;;
    "RIPE")
      curl -s "https://stat.ripe.net/data/prefix-overview/data.json?resource=$ip" | jq -r '.data.asns[0], .data.holder, .data.country' 2>/dev/null
      ;;
    *)
      echo "Invalid database: $database" >&2
      return 1
      ;;
  esac
}

# --- Main Script ---

# IP databases to use
databases=(
  "whois"
  "ipinfo.io"
  "ipapi.co"
  "RIPE"
)

# --- IP Address Retrieval ---

public_ip=$(get_public_ip)
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Exiting due to error retrieving public IP.${NC}"
  exit 1
fi

echo -e "${GREEN}--- Public IP Address: $public_ip ---${NC}\n"

# --- Database Information Retrieval ---

echo -e "${GREEN}--- Information from Databases ---${NC}"
database_info=()

for database in "${databases[@]}"; do
  info=$(get_info_from_db "$public_ip" "$database")
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error retrieving information from $database. Skipping...${NC}"
    continue
  fi

  database_info+=("$info")
  echo -e "${GREEN}Database: $database${NC}"
  echo "$info"
  echo # Add a line break after each database
done

# --- Data Comparison & Analysis ---

echo -e "${GREEN}--- Comparison ---${NC}"

for field in "ASN" "Country" "Region" "City" "Organization"; do
  echo -e "${GREEN}Field: $field${NC}"
  for i in "${!databases[@]}"; do
    database=${databases[$i]}
    value=$(echo "${database_info[$i]}" | awk -v field="$field" '{for(i=1;i<=NF;i++) {if ($i ~ field || $i ~ tolower(field)) {print $(i+1)}}}' | tr '\n' ' ')
    echo -e "  $database: $value"
  done
  echo
done
