#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOTAL_REQUESTS="${TOTAL_REQUESTS:-40}"
SLEEP_SECONDS="${SLEEP_SECONDS:-0.2}"

success_count=0
error_count=0

echo "Sending ${TOTAL_REQUESTS} requests to ${BASE_URL}"
echo "Target mix: ~75% success, ~25% errors"
echo

for ((i=1; i<=TOTAL_REQUESTS; i++)); do
  # Pattern:
  # 1-3 success
  # 4 out-of-stock
  # 5 forced failure
  # 6 slow success
  # then repeat
  mod=$(( i % 6 ))

  case "$mod" in
    1|2|3)
      label="success"
      url="${BASE_URL}/api/checkout?sku=SKU123&qty=1"
      ;;
    4)
      label="out_of_stock"
      url="${BASE_URL}/api/checkout?sku=SKU456&qty=1"
      ;;
    5)
      label="forced_failure"
      url="${BASE_URL}/api/checkout?sku=SKU123&qty=1&fail=true"
      ;;
    0)
      label="slow_success"
      url="${BASE_URL}/api/checkout?sku=SKU123&qty=1&delayMs=1000"
      ;;
  esac

  status_code="$(curl -s -o /tmp/storefront-response.$$ -w "%{http_code}" "$url")"
  body="$(cat /tmp/storefront-response.$$)"
  rm -f /tmp/storefront-response.$$

  if [[ "$status_code" =~ ^2 ]]; then
    ((success_count+=1))
  else
    ((error_count+=1))
  fi

  printf "[%02d/%02d] %-15s status=%s\n" "$i" "$TOTAL_REQUESTS" "$label" "$status_code"

  sleep "$SLEEP_SECONDS"
done

echo
echo "Done."
echo "Successful responses: ${success_count}"
echo "Non-2xx responses:    ${error_count}"
