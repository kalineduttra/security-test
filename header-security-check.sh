#!/bin/bash

URL=$1

# Check if the URL was provided
if [ -z "$URL" ]; then
  echo "Usage: $0 <URL>"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Capture all headers
echo -e "${YELLOW}--- Getting headers from $URL ---${NC}"
HEADER=$(curl -ILs --max-redirs 10 "$URL" | tr '[:upper:]' '[:lower:]')

# Check if the request was successful
if [ -z "$HEADER" ]; then
  echo -e "${RED}Error: Could not get headers from URL '$URL'. Please check the URL and connectivity.${NC}"
  exit 1
fi

# Function to check for the presence of a header
check_header() {
  local header_name=$1
  local message_present=$2
  local message_absent=$3

  if echo "$HEADER" | grep -q "$header_name"; then
    echo -e "  - ${header_name}: ${GREEN}Present.${NC} $message_present"
  else
    echo -e "  - ${header_name}: ${RED}Absent.${NC} $message_absent"
  fi
}

# All received headers
echo -e "${YELLOW}--- Received headers ---${NC}"
echo "$HEADER"
echo -e "\n"

# Check header security
echo -e "${YELLOW}Security Report for: $URL${NC}"
check_strict_transport_security() {
  if echo "$HEADER" | grep -q "strict-transport-security"; then
    if echo "$HEADER" | grep -q "max-age=[1-9][0-9]*;.*includesubdomains"; then
      echo -e "  - Strict-Transport-Security (HSTS): ${GREEN}Present and Secure.${NC} High max-age and subdomains included."
    else
      echo -e "  - Strict-Transport-Security (HSTS): ${YELLOW}Insecure.${NC} Low max-age or lack of 'includesubdomains'."
    fi
  else
    echo -e "  - Strict-Transport-Security (HSTS): ${RED}Absent.${NC} Recommendation: Implement to enforce HTTPS."
  fi
}

check_x_content_type_options() {
  if echo "$HEADER" | grep -q "x-content-type-options:.*nosniff"; then
    echo -e "  - X-Content-Type-Options: ${GREEN}Present and Secure.${NC}"
  else
    echo -e "  - X-Content-Type-Options: ${YELLOW}Insecure/Absent.${NC} Recommendation: Use 'nosniff'."
  fi
}

check_x_frame_options() {
  if echo "$HEADER" | grep -q "x-frame-options:.*deny\|x-frame-options:.*sameorigin"; then
    echo -e "  - X-Frame-Options: ${GREEN}Present and Secure.${NC}"
  else
    echo -e "  - X-Frame-Options: ${YELLOW}Insecure/Absent.${NC} Recommendation: Use 'DENY' or 'SAMEORIGIN'."
  fi
}

check_content_security-policy() {
  if echo "$HEADER" | grep -q "content-security-policy"; then
    if echo "$HEADER" | grep -q "unsafe-inline" || echo "$HEADER" | grep -q "unsafe-eval"; then
      echo -e "  - Content-Security-Policy (CSP): ${YELLOW}Insecure.${NC} Contains 'unsafe-inline' or 'unsafe-eval'."
    else
      echo -e "  - Content-Security-Policy (CSP): ${GREEN}Present and Potentially Secure.${NC}"
    fi
  else
    echo -e "  - Content-Security-Policy (CSP): ${RED}Absent.${NC} Recommendation: Implement a robust policy to mitigate XSS."
  fi
}

check_referrer_policy() {
  if echo "$HEADER" | grep -q "referrer-policy:.*no-referrer\|referrer-policy:.*same-origin\|referrer-policy:.*strict-origin-when-cross-origin"; then
    echo -e "  - Referrer-Policy: ${GREEN}Present and Secure.${NC}"
  else
    echo -e "  - Referrer-Policy: ${YELLOW}Insecure/Absent.${NC} Recommendation: Use 'strict-origin-when-cross-origin' to protect privacy."
  fi
}

check_permission_policy() {
  if echo "$HEADER" | grep -q "permissions-policy"; then
    echo -e "  - Permissions-Policy: ${GREEN}Present.${NC}"
  else
    echo -e "  - Permissions-Policy: ${RED}Absent.${NC} Recommendation: Implement to disable unused sensitive APIs."
  fi
}

# Execute validation functions
check_strict_transport_security
check_x_content_type_options
check_x_frame_options
check_content_security-policy
check_referrer_policy
check_permission_policy
