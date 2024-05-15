#!/bin/bash

# --- ip_comparison_checker.sh ---

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to obtain IP address using different methods
get_ip() {
  method=$1
  case $method in
    "ip")
      ip a show scope global | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}'
      ;;
    "hostname")
      hostname -I | awk '{print $1}'
      ;;
    "ifconfig")
      ifconfig | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}'
      ;;
    "curl")
      curl -s https://ipinfo.io/ip
      ;;
    *)
      echo "Invalid method: $method" >&2
      return 1
      ;;
  esac
}

# Function to obtain information from a specific database
get_info_from_db() {
  ip=$1
  database=$2
  case $database in
    "whois")
      whois $ip | grep -iE 'origin|netname|country|stateprov|city'
      ;;
    "ipinfo.io")
      curl -s "https://ipinfo.io/$ip" | jq -r '.org, .country, .region, .city, .asn'
      ;;
    "ipapi.co")
      curl -s "https://ipapi.co/$ip/json/" | jq -r '.asn, .country_name, .region, .city'
      ;;
    "RIPE")
      curl -s "https://stat.ripe.net/data/prefix-overview/data.json?resource=$ip" | jq -r '.data.asns[0], .data.holder, .data.country'
      ;;
    *)
      echo "Invalid database: $database" >&2
      return 1
      ;;
  esac
}

# --- Main Script ---

# Platforms and their corresponding methods
platforms=(
  "a:ip"
  "b:hostname"
  "c:ifconfig"
  "d:curl"
)

# IP databases to use
databases=(
  "whois"
  "ipinfo.io"
  "ipapi.co"
  "RIPE"
)

# Initialize data structures to store results
ip_addresses=()
info_data=()

# --- IP Address Retrieval --- 

echo -e "${GREEN}--- IP Address Retrieval ---${NC}"
for platform in "${platforms[@]}"; do
  platform_name=${platform%:*}
  method=${platform#*:}

  ip=$(get_ip $method)
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error retrieving IP for platform $platform_name${NC}"
    continue # Skip to the next platform if there's an error
  fi

  ip_addresses+=("$platform_name:$ip")
  echo -e "Platform $platform_name: $ip"
done

# --- Database Information Retrieval ---

echo -e "\n${GREEN}--- Information from Databases ---${NC}"
for platform in "${platforms[@]}"; do
  platform_name=${platform%:*}
  ip=$(echo "${ip_addresses[@]}" | grep "$platform_name:" | cut -d: -f2)

  echo -e "Platform $platform_name:"
  for database in "${databases[@]}"; do
    info=$(get_info_from_db $ip $database)
    if [[ $? -ne 0 ]]; then
      echo -e "  ${RED}Error retrieving information from $database${NC}"
      continue 
    fi

    info_data+=("$platform_name:$database:$info")
    echo -e "  ${GREEN}$database:${NC}"
    echo -e "    $info"
  done
done

# --- Data Comparison & Analysis (Basic) --- 

echo -e "\n${GREEN}--- Basic Comparison ---${NC}"

for database in "${databases[@]}"; do
  echo -e "${GREEN}Database: $database${NC}" 
  for field in "ASN" "Country" "Region" "City"; do # Fields to compare
    values=$(echo "${info_data[@]}" | grep "$database:" | awk -v field="$field" '{for(i=1;i<=NF;i++) {if ($i ~ field) {print $(i+1)}}}' | sort | uniq) 
    num_values=$(echo "$values" | wc -l)
    if [[ $num_values -eq 1 ]]; then
      echo -e "  ${GREEN}$field: Consistent ($values)${NC}"
    else
      echo -e "  ${RED}$field: Discrepancies${NC}"
      echo -e "    $values"
    fi
  done
  echo "" # Add a line break between databases
done
