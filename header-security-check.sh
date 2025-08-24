#!/bin/bash

URL=$1

# Check if the URL was provided
if [ -z "$URL" ]; then
  echo "Usage: $0 <URL>"
  exit 1
fi

# Validate URL format
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Error: URL must start with http:// or https://"
  exit 1
fi

# Capture all headers with better error handling
HEADER=$(curl -ILs --max-redirs 10 --max-time 30 --retry 2 -H "User-Agent: Security-Header-Checker/1.0" "$URL" 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]')

# Check if the request was successful
if [ -z "$HEADER" ]; then
  echo "Error: Could not get headers from URL '$URL'. Please check:"
  echo "  - URL validity"
  echo "  - Network connectivity"
  echo "  - Server availability"
  exit 1
fi

# Check for HTTP errors
HTTP_STATUS=$(echo "$HEADER" | grep -E "^http/" | tail -1 | awk '{print $2}')
if [[ "$HTTP_STATUS" =~ ^[45][0-9][0-9]$ ]]; then
  echo "Error: Server returned HTTP $HTTP_STATUS for URL '$URL'"
  exit 1
fi

# Extract just the headers (remove status lines)
HEADERS_ONLY=$(echo "$HEADER" | grep -E -v "^(http/|$|location:|content-)" | sed '/^$/q')

# Start markdown output with timestamp
echo "# Security Header Report"
echo "**Target URL:** \`$URL\`"
echo "**HTTP Status:** $HTTP_STATUS"

echo "## Received Headers"
echo "\`\`\`http"
echo "$HEADERS_ONLY"
echo "\`\`\`"

echo "## Security Header Analysis"
echo "| Header | Status | Value | Recommendation |"
echo "|--------|--------|-------|----------------|"

# Function to extract header value
get_header_value() {
  local header_name=$1
  echo "$HEADER" | grep -E "^$header_name:" | head -1 | sed "s/^$header_name:\s*//i" | tr -d '\r'
}

# Function to output markdown table rows
output_markdown_row() {
  local header_name=$1
  local status=$2
  local value=$3
  local recommendation=$4
  echo "| $header_name | $status | \`$value\` | $recommendation |"
}

# Check header security functions
check_strict_transport_security() {
  local value=$(get_header_value "strict-transport-security")
  if [ -n "$value" ]; then
    if echo "$value" | grep -q "max-age=[1-9][0-9]*" && echo "$value" | grep -q "includesubdomains"; then
      output_markdown_row "Strict-Transport-Security" "Secure" "$value" "High max-age with includeSubDomains"
    elif echo "$value" | grep -q "max-age=[1-9][0-9]*"; then
      output_markdown_row "Strict-Transport-Security" "Partial" "$value" "Add includeSubDomains directive"
    else
      output_markdown_row "Strict-Transport-Security" "Insecure" "$value" "Increase max-age (min 31536000)"
    fi
  else
    output_markdown_row "Strict-Transport-Security" "Absent" "N/A" "Implement HSTS with min 31536000 max-age"
  fi
}

check_x_content_type_options() {
  local value=$(get_header_value "x-content-type-options")
  if [ -n "$value" ] && echo "$value" | grep -q "nosniff"; then
    output_markdown_row "X-Content-Type-Options" "Secure" "$value" "Properly configured"
  else
    output_markdown_row "X-Content-Type-Options" "Absent" "N/A" "Set to 'nosniff' to prevent MIME sniffing"
  fi
}

check_x_frame_options() {
  local value=$(get_header_value "x-frame-options")
  if [ -n "$value" ] && echo "$value" | grep -q -E "^(deny|sameorigin)$"; then
    output_markdown_row "X-Frame-Options" "Secure" "$value" "Properly configured"
  elif [ -n "$value" ]; then
    output_markdown_row "X-Frame-Options" "Partial" "$value" "Consider using 'DENY' or 'SAMEORIGIN'"
  else
    output_markdown_row "X-Frame-Options" "Absent" "N/A" "Set to 'DENY' or 'SAMEORIGIN' to prevent clickjacking"
  fi
}

check_content_security_policy() {
  local value=$(get_header_value "content-security-policy")
  if [ -n "$value" ]; then
    if echo "$value" | grep -q -E "(unsafe-inline|unsafe-eval|\\*)"; then
      output_markdown_row "Content-Security-Policy" "Partial" "$value" "Contains unsafe directives"
    else
      output_markdown_row "Content-Security-Policy" "Secure" "$value" "Well configured"
    fi
  else
    output_markdown_row "Content-Security-Policy" "Absent" "N/A" "Implement CSP to mitigate XSS attacks"
  fi
}

check_referrer_policy() {
  local value=$(get_header_value "referrer-policy")
  local secure_policies="no-referrer|strict-origin|strict-origin-when-cross-origin|no-referrer-when-downgrade"
  if [ -n "$value" ] && echo "$value" | grep -q -E "($secure_policies)"; then
    output_markdown_row "Referrer-Policy" "Secure" "$value" "Properly configured"
  elif [ -n "$value" ]; then
    output_markdown_row "Referrer-Policy" "Partial" "$value" "Consider stricter policy"
  else
    output_markdown_row "Referrer-Policy" "Absent" "N/A" "Set to 'strict-origin-when-cross-origin'"
  fi
}

check_permission_policy() {
  local value=$(get_header_value "permissions-policy")
  if [ -n "$value" ]; then
    output_markdown_row "Permissions-Policy" "Present" "$value" "Properly configured"
  else
    output_markdown_row "Permissions-Policy" "Absent" "N/A" "Implement to restrict sensitive features"
  fi
}

# Execute validation functions
check_strict_transport_security
check_x_content_type_options
check_x_frame_options
check_content_security_policy
check_referrer_policy
check_permission_policy

exit 0