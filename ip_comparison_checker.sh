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

# Platforms (for labeling) - we use the same method (curl) for all 
platforms=(
  "a:curl"
  "b:curl"
  "c:curl"
  "d:curl"
)

# IP databases to use
databases=(
  "whois"
  "ipinfo.io"
  "ipapi.co"
  "RIPE"
)

# --- IP Address Retrieval ---

echo -e "${GREEN}--- IP Address Retrieval ---${NC}"
public_ip=$(get_public_ip)
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Exiting due to error retrieving public IP.${NC}"
  exit 1
fi

for platform in "${platforms[@]}"; do
  platform_name=${platform%:*}
  echo -e "Platform $platform_name: $public_ip"
done

echo 

# --- Database Information Retrieval ---

echo -e "${GREEN}--- Information from Databases ---${NC}"
platform_info=() # Array to store information for each platform

for platform in "${platforms[@]}"; do
  platform_name=${platform%:*}
  echo -e "Platform $platform_name:"
  
  for database in "${databases[@]}"; do
    info=$(get_info_from_db "$public_ip" "$database")
    if [[ $? -ne 0 ]]; then
      echo -e "  ${RED}Error retrieving information from $database. Skipping...${NC}"
      continue
    fi
    platform_info+=("$platform_name:$database:$info") # Store in platform_info
    echo -e "  ${GREEN}$database:${NC}"
    echo "    $info" 
  done
  echo # Add line break after each platform 
done

# --- Data Comparison & Analysis ---

echo -e "${GREEN}--- Basic Comparison ---${NC}"

for database in "${databases[@]}"; do
  echo -e "${GREEN}Database: $database${NC}" 

  for field in "ASN" "Country" "Region" "City" "Organization"; do 
    values=$(echo "${platform_info[@]}" | grep "$database:" | awk -v field="$field" '{for(i=1;i<=NF;i++) {if ($i ~ field || $i ~ tolower(field)) {print $(i+1)}}}' | sort | uniq) 
    num_values=$(echo "$values" | wc -l)

    if [[ $num_values -eq 1 ]]; then
      echo -e "  ${GREEN}$field: Consistent ($values)${NC}"
    else
      echo -e "  ${RED}$field: Discrepancies${NC}"
      echo "    $values"
    fi
  done
  echo # Add a line break between databases
done
