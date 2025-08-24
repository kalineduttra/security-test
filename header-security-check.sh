#!/bin/bash

URL=$1

# Check if the URL was provided
if [ -z "$URL" ]; then
  echo "Usage: $0 <URL>"
  exit 1
fi

# Capture all headers
echo "--- Getting headers from $URL ---"
HEADER=$(curl -ILs --max-redirs 10 "$URL" | tr '[:upper:]' '[:lower:]')

# Check if the request was successful
if [ -z "$HEADER" ]; then
  echo "Error: Could not get headers from URL '$URL'. Please check the URL and connectivity."
  exit 1
fi

# Function to check for the presence of a header
check_header() {
  local header_name=$1
  local message_present=$2
  local message_absent=$3

  if echo "$HEADER" | grep -q "$header_name"; then
    echo "  - ${header_name}: Present. $message_present"
  else
    echo "  - ${header_name}: Absent. $message_absent"
  fi
}

# All received headers
echo "--- Received headers ---"
echo "$HEADER"

# Check header security
echo "Security Report for: $URL"
check_strict_transport_security() {
  if echo "$HEADER" | grep -q "strict-transport-security"; then
    if echo "$HEADER" | grep -q "max-age=[1-9][0-9]*;.*includesubdomains"; then
      echo "  - Strict-Transport-Security (HSTS): Present and Secure. High max-age and subdomains included."
    else
      echo "  - Strict-Transport-Security (HSTS): Insecure. Low max-age or lack of 'includesubdomains'."
    fi
  else
    echo "  - Strict-Transport-Security (HSTS): Absent. Recommendation: Implement to enforce HTTPS."
  fi
}

check_x_content_type_options() {
  if echo "$HEADER" | grep -q "x-content-type-options:.*nosniff"; then
    echo "  - X-Content-Type-Options: Present and Secure."
  else
    echo "  - X-Content-Type-Options: Insecure/Absent. Recommendation: Use 'nosniff'."
  fi
}

check_x_frame_options() {
  if echo "$HEADER" | grep -q "x-frame-options:.*deny\|x-frame-options:.*sameorigin"; then
    echo "  - X-Frame-Options: Present and Secure."
  else
    echo "  - X-Frame-Options: Insecure/Absent. Recommendation: Use 'DENY' or 'SAMEORIGIN'."
  fi
}

check_content_security-policy() {
  if echo "$HEADER" | grep -q "content-security-policy"; then
    if echo "$HEADER" | grep -q "unsafe-inline" || echo "$HEADER" | grep -q "unsafe-eval"; then
      echo "  - Content-Security-Policy (CSP): Insecure. Contains 'unsafe-inline' or 'unsafe-eval'."
    else
      echo "  - Content-Security-Policy (CSP): Present and Potentially Secure."
    fi
  else
    echo "  - Content-Security-Policy (CSP): Absent. Recommendation: Implement a robust policy to mitigate XSS."
  fi
}

check_referrer_policy() {
  if echo "$HEADER" | grep -q "referrer-policy:.*no-referrer\|referrer-policy:.*same-origin\|referrer-policy:.*strict-origin-when-cross-origin"; then
    echo "  - Referrer-Policy: Present and Secure."
  else
    echo "  - Referrer-Policy: Insecure/Absent. Recommendation: Use 'strict-origin-when-cross-origin' to protect privacy."
  fi
}

check_permission_policy() {
  if echo "$HEADER" | grep -q "permissions-policy"; then
    echo "  - Permissions-Policy: Present."
  else
    echo "  - Permissions-Policy: Absent. Recommendation: Implement to disable unused sensitive APIs."
  fi
}

# Execute validation functions
check_strict_transport_security
check_x_content_type_options
check_x_frame_options
check_content_security-policy
check_referrer_policy
check_permission_policy
