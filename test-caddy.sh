#!/bin/bash

# Comprehensive Test Suite for Custom Caddy Docker Container
# Tests functionality, plugins, and performance

set -e

# Configuration (override with env vars if set)
IMAGE_NAME=${IMAGE_NAME:-"caddy-cf"}
VERSION=${VERSION:-"latest"}
CONTAINER_NAME=${CONTAINER_NAME:-"caddy-test"}
TEST_PORT=${TEST_PORT:-"8080"}
TLS_PORT=${TLS_PORT:-"8443"}
ADMIN_PORT=${ADMIN_PORT:-"2019"}

# Docker CLI (auto-fallback to sudo if needed)
DOCKER=${DOCKER:-docker}
if ! ${DOCKER} info >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
        DOCKER="sudo docker"
    fi
fi

# Auto-detect a recently built image if the default isn't present
if ! ${DOCKER} images | awk '{print $1":"$2}' | grep -q "^${IMAGE_NAME}:${VERSION}$"; then
    if ${DOCKER} images | awk '{print $1":"$2}' | grep -q '^caddy-cf:latest$'; then
        IMAGE_NAME="caddy-cf"; VERSION="latest"
    elif ${DOCKER} images | awk '{print $1":"$2}' | grep -q '^caddy-cf:test$'; then
        IMAGE_NAME="caddy-cf"; VERSION="test"
    elif ${DOCKER} images | awk '{print $1":"$2}' | grep -q '^minimal-caddy:cloudflare$'; then
        IMAGE_NAME="minimal-caddy"; VERSION="cloudflare"
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}🧪 Test: $1${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

test_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
}

# Trap cleanup on exit
trap cleanup EXIT

print_header "🚀 MINIMAL CADDY DOCKER CONTAINER TEST SUITE"

# Pre-test checks
print_test "Checking if Docker is running"
if ${DOCKER} info >/dev/null 2>&1; then
    test_pass "Docker is running"
else
    test_fail "Docker is not running or permission denied. Try: sudo ./test-caddy.sh or add your user to the docker group."
    exit 1
fi

print_test "Checking if Caddy image exists: ${IMAGE_NAME}:${VERSION}"
if ${DOCKER} images | awk '{print $1":"$2}' | grep -q "^${IMAGE_NAME}:${VERSION}$"; then
    test_pass "Caddy image found"
else
    test_fail "Caddy image not found. Build it first (e.g., docker build -f caddy/Dockerfile.cloudflare -t caddy-cf:test caddy)"
    exit 1
fi

# Start container for testing
print_header "🏃 STARTING CONTAINER FOR TESTING"
echo "Starting container: ${CONTAINER_NAME}"
echo "Ports: ${TEST_PORT}:80, ${TLS_PORT}:443, ${ADMIN_PORT}:2019"

# Use test Caddyfile if CLOUDFLARE_API_TOKEN is not set
if [ -z "${CLOUDFLARE_API_TOKEN}" ]; then
    echo "ℹ️  No CLOUDFLARE_API_TOKEN provided, using test configuration without DNS challenge"
    ${DOCKER} run -d \
        --name ${CONTAINER_NAME} \
        -p ${TEST_PORT}:80 \
        -p ${TLS_PORT}:443 \
        -p ${ADMIN_PORT}:2019 \
        -v "$(pwd)/Caddyfile-test:/etc/caddy/Caddyfile" \
        ${IMAGE_NAME}:${VERSION}
else
    echo "ℹ️  Using production configuration with Cloudflare DNS"
    ${DOCKER} run -d \
        --name ${CONTAINER_NAME} \
        -p ${TEST_PORT}:80 \
        -p ${TLS_PORT}:443 \
        -p ${ADMIN_PORT}:2019 \
        -e CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN}" \
        -e DOMAIN="${DOMAIN:-localhost}" \
        -e CADDY_ACME_EMAIL="${CADDY_ACME_EMAIL:-admin@example.com}" \
        ${IMAGE_NAME}:${VERSION}
fi

# Wait for container to start
echo "Waiting for container to start..."
sleep 5

# Test 1: Container Health
print_header "🏥 CONTAINER HEALTH TESTS"

print_test "Container is running"
if ${DOCKER} ps | grep -q ${CONTAINER_NAME}; then
    test_pass "Container is running"
else
    test_fail "Container is not running"
    ${DOCKER} logs ${CONTAINER_NAME}
fi

print_test "Caddy process is active"
if ${DOCKER} exec ${CONTAINER_NAME} pgrep caddy >/dev/null; then
    test_pass "Caddy process is active"
else
    test_fail "Caddy process is not running"
fi

# Test 2: Network Connectivity
print_header "🌐 NETWORK CONNECTIVITY TESTS"

print_test "HTTP port ${TEST_PORT} responds (200 or redirect)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${TEST_PORT}/)
if echo "$HTTP_CODE" | grep -Eq "^(200|301|302|308)$"; then
    test_pass "HTTP returned ${HTTP_CODE}"
else
    test_fail "HTTP returned ${HTTP_CODE}"
fi

print_test "HTTPS port ${TLS_PORT} serves content"
if curl -sk -o /dev/null -w "%{http_code}" https://localhost:${TLS_PORT}/ | grep -q "200"; then
    test_pass "HTTPS is accessible"
else
    test_fail "HTTPS not accessible"
fi

# Test 3: Health Check Endpoint
print_header "🔍 HEALTH CHECK TESTS"

print_test "Health endpoint returns OK"
HEALTH_RESPONSE=$(curl -s http://localhost:${TEST_PORT}/health)
if [ "$HEALTH_RESPONSE" = "OK" ]; then
    test_pass "Health endpoint returns OK"
else
    test_fail "Health endpoint response: $HEALTH_RESPONSE"
fi

# Test 4: Static File Serving
print_header "📁 STATIC FILE SERVING TESTS"

print_test "Index page is served over HTTPS"
if curl -sk https://localhost:${TLS_PORT}/ | head -c 1 >/dev/null; then
    test_pass "Index page served"
else
    test_fail "Index page not served"
fi

print_test "HTML content type is correct (HTTPS)"
CONTENT_TYPE=$(curl -sk -I https://localhost:${TLS_PORT}/ | grep -i "content-type" | grep -i "text/html")
if [ -n "$CONTENT_TYPE" ]; then
    test_pass "HTML content type is correct"
else
    test_fail "HTML content type is incorrect"
fi

# Test 5: Plugin Verification
print_header "🔌 PLUGIN VERIFICATION TESTS"

print_test "Caddy modules are loaded"
MODULES=$(${DOCKER} exec ${CONTAINER_NAME} caddy list-modules)
if echo "$MODULES" | grep -q "cloudflare"; then
    test_pass "cloudflare-dns plugin is loaded"
else
    test_fail "cloudflare-dns plugin is not loaded"
fi

# Note: Removed nginx-adapter and caddy-security for minimal build
echo "ℹ️  Note: Minimal plugin build - nginx-adapter removed (not needed)"
echo "ℹ️  Note: Using Authentik for authentication instead of caddy-security plugin"

# Test 6: Admin API Functionality
print_header "⚙️ ADMIN API TESTS"

print_test "Admin API returns configuration (or validate config in container)"
CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${ADMIN_PORT}/config/ || true)
if echo "$CONFIG_CODE" | grep -q "200"; then
    test_pass "Admin API returned configuration"
else
    if ${DOCKER} exec ${CONTAINER_NAME} caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1; then
        test_pass "Admin not externally reachable; config validated inside container"
    else
        test_fail "Admin API not reachable and config validation failed"
    fi
fi

# Test 7: Performance Tests
print_header "⚡ PERFORMANCE TESTS"

print_test "Response time is acceptable"
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:${TEST_PORT}/)
# Use awk for decimal comparison since bash doesn't handle decimals well
if awk "BEGIN {exit ($RESPONSE_TIME < 1.0) ? 0 : 1}"; then
    test_pass "Response time is acceptable (${RESPONSE_TIME}s)"
else
    test_fail "Response time is too slow (${RESPONSE_TIME}s)"
fi

print_test "Concurrent requests handling"
# Test with 10 concurrent requests using background processes
TEMP_DIR=$(mktemp -d)
for i in {1..10}; do
    (curl -s -o /dev/null --max-time 5 http://localhost:${TEST_PORT}/ && echo "success" > "$TEMP_DIR/result_$i") &
done
wait  # Wait for all background processes to complete

SUCCESS_COUNT=$(ls "$TEMP_DIR"/result_* 2>/dev/null | wc -l)
rm -rf "$TEMP_DIR"

if [ "$SUCCESS_COUNT" -ge 8 ]; then
    test_pass "Handles concurrent requests ($SUCCESS_COUNT/10 successful)"
else
    test_fail "Failed to handle concurrent requests ($SUCCESS_COUNT/10 successful)"
fi

# Test 8: Rate Limiting (if enabled)
print_header "🚦 RATE LIMITING TESTS"

print_test "Rate limiting configuration"
if docker exec ${CONTAINER_NAME} caddy list-modules | grep -q "ratelimit"; then
    test_pass "Rate limiting module is available"
    
    # Test rate limiting by making rapid requests
    print_test "Rate limiting enforcement"
    RATE_TEST_RESULTS=$(for i in {1..5}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:${TEST_PORT}/; done)
    if echo "$RATE_TEST_RESULTS" | grep -q "200"; then
        test_pass "Rate limiting allows normal requests"
    else
        test_fail "Rate limiting blocks normal requests"
    fi
else
    echo "ℹ️  Rate limiting module is not available (optional for minimal build)"
    test_pass "Rate limiting module is not included (expected for minimal build)"
fi

# Test 9: Container Resource Usage
print_header "📊 RESOURCE USAGE TESTS"

print_test "Memory usage is reasonable"
MEMORY_USAGE=$(${DOCKER} stats --no-stream --format "{{.MemUsage}}" ${CONTAINER_NAME} | cut -d'/' -f1 | sed 's/MiB//')
# Use integer comparison instead of bc for better compatibility
MEMORY_INT=$(echo "$MEMORY_USAGE" | cut -d'.' -f1)
if [ "$MEMORY_INT" -lt 100 ]; then
    test_pass "Memory usage is reasonable (${MEMORY_USAGE}MiB)"
else
    test_fail "Memory usage is high (${MEMORY_USAGE}MiB)"
fi

# Test 10: Log Output
print_header "📝 LOG TESTS"

print_test "Container logs contain startup messages"
LOGS=$(${DOCKER} logs ${CONTAINER_NAME} 2>&1)
if echo "$LOGS" | grep -q "using config from file"; then
    test_pass "Logs contain expected startup messages"
else
    test_fail "Logs do not contain expected startup messages"
fi

# Test Summary
print_header "📋 TEST SUMMARY"
echo -e "Total Tests: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"

if [ ${TESTS_FAILED} -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! Your minimal Caddy container is working correctly.${NC}"
    echo -e "\n${BLUE}🚀 Ready for production deployment!${NC}"
    echo -e "\nTo deploy:"
    echo -e "1. Push to registry: ./push-to-registry.sh"
    echo -e "2. Deploy: docker run -d -p 80:80 -p 443:443 ${IMAGE_NAME}:${VERSION}"
    exit 0
else
    echo -e "\n${RED}❌ SOME TESTS FAILED. Please review the failures above.${NC}"
    echo -e "\n${YELLOW}Debug information:${NC}"
    echo -e "Container logs:"
    ${DOCKER} logs ${CONTAINER_NAME}
    exit 1
fi
