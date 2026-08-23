#!/bin/bash

# ============================================
# StudioBook Performance Benchmark Runner
# ============================================
# This script runs performance benchmarks and validates against thresholds
# Usage: ./run_benchmarks.sh [base_url] [--ci]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${1:-http://localhost:8000/api/v1}"
CI_MODE="${2:-}"
REPORT_FILE="benchmark-report-$(date +%Y%m%d-%H%M%S).md"
FAILURES=0
WARNINGS=0
TESTS_RUN=0
TESTS_PASSED=0

# Thresholds (from performance_benchmarks.json)
HEALTH_P95_THRESHOLD=100
STUDIOS_P95_THRESHOLD=200
SEARCH_P95_THRESHOLD=300
ERROR_RATE_THRESHOLD=1.0
HEALTH_RPS_THRESHOLD=500
STUDIOS_RPS_THRESHOLD=200

# ============================================
# Helper Functions
# ============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILURES=$((FAILURES + 1))
}

check_threshold() {
    local value=$1
    local threshold=$2
    local comparison=$3
    local metric_name=$4
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    case $comparison in
        "lte")
            if (( $(echo "$value <= $threshold" | bc -l) )); then
                log_success "$metric_name: ${value} <= ${threshold}"
                return 0
            else
                log_failure "$metric_name: ${value} > ${threshold}"
                return 1
            fi
            ;;
        "gte")
            if (( $(echo "$value >= $threshold" | bc -l) )); then
                log_success "$metric_name: ${value} >= ${threshold}"
                return 0
            else
                log_failure "$metric_name: ${value} < ${threshold}"
                return 1
            fi
            ;;
        *)
            log_warning "Unknown comparison: $comparison"
            return 1
            ;;
    esac
}

# ============================================
# Initialize Report
# ============================================

init_report() {
    cat > "$REPORT_FILE" << EOF
# Performance Benchmark Report

**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Base URL:** $BASE_URL
**Commit:** ${GITHUB_SHA:-local}

---

## Test Summary

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
EOF
}

# ============================================
# API Benchmarks
# ============================================

run_health_check_benchmark() {
    log_info "Running Health Check Benchmark..."
    
    local result
    result=$(ab -n 1000 -c 50 -q -r "$BASE_URL/../health" 2>&1)
    
    # Extract metrics
    local rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
    local mean_time=$(echo "$result" | grep "Time per request.*mean" | head -1 | awk '{print $4}')
    local p95_time=$(echo "$result" | grep "95%" | awk '{print $2}')
    local error_rate=$(echo "$result" | grep "Failed requests" | awk '{print $3}')
    
    if [ -z "$rps" ]; then
        log_failure "Could not parse health check results"
        return 1
    fi
    
    # Validate thresholds
    check_threshold "$p95_time" "$HEALTH_P95_THRESHOLD" "lte" "Health Check P95 Response Time"
    check_threshold "$rps" "$HEALTH_RPS_THRESHOLD" "gte" "Health Check Throughput"
    
    # Add to report
    echo "| Health Check P95 | ${p95_time}ms | ${HEALTH_P95_THRESHOLD}ms | $(if (( $(echo "$p95_time <= $HEALTH_P95_THRESHOLD" | bc -l) )); then echo "✅"; else echo "❌"; fi) |" >> "$REPORT_FILE"
    echo "| Health Check RPS | ${rps} | ${HEALTH_RPS_THRESHOLD} | $(if (( $(echo "$rps >= $HEALTH_RPS_THRESHOLD" | bc -l) )); then echo "✅"; else echo "❌"; fi) |" >> "$REPORT_FILE"
    
    log_info "Health Check: ${rps} req/s, P95: ${p95_time}ms"
}

run_studios_benchmark() {
    log_info "Running Studios List Benchmark..."
    
    local result
    result=$(ab -n 500 -c 25 -q -r "$BASE_URL/studios" 2>&1)
    
    local rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
    local p95_time=$(echo "$result" | grep "95%" | awk '{print $2}')
    
    if [ -z "$rps" ]; then
        log_failure "Could not parse studios benchmark results"
        return 1
    fi
    
    check_threshold "$p95_time" "$STUDIOS_P95_THRESHOLD" "lte" "Studios List P95 Response Time"
    check_threshold "$rps" "$STUDIOS_RPS_THRESHOLD" "gte" "Studios List Throughput"
    
    echo "| Studios P95 | ${p95_time}ms | ${STUDIOS_P95_THRESHOLD}ms | $(if (( $(echo "$p95_time <= $STUDIOS_P95_THRESHOLD" | bc -l) )); then echo "✅"; else echo "❌"; fi) |" >> "$REPORT_FILE"
    echo "| Studios RPS | ${rps} | ${STUDIOS_RPS_THRESHOLD} | $(if (( $(echo "$rps >= $STUDIOS_RPS_THRESHOLD" | bc -l) )); then echo "✅"; else echo "❌"; fi) |" >> "$REPORT_FILE"
    
    log_info "Studios List: ${rps} req/s, P95: ${p95_time}ms"
}

run_search_benchmark() {
    log_info "Running Search Benchmark..."
    
    local result
    result=$(ab -n 500 -c 25 -q -r "$BASE_URL/studios?search=music" 2>&1)
    
    local rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
    local p95_time=$(echo "$result" | grep "95%" | awk '{print $2}')
    
    if [ -z "$rps" ]; then
        log_failure "Could not parse search benchmark results"
        return 1
    fi
    
    check_threshold "$p95_time" "$SEARCH_P95_THRESHOLD" "lte" "Search P95 Response Time"
    
    echo "| Search P95 | ${p95_time}ms | ${SEARCH_P95_THRESHOLD}ms | $(if (( $(echo "$p95_time <= $SEARCH_P95_THRESHOLD" | bc -l) )); then echo "✅"; else echo "❌"; fi) |" >> "$REPORT_FILE"
    
    log_info "Search: ${rps} req/s, P95: ${p95_time}ms"
}

run_concurrent_benchmark() {
    log_info "Running Concurrent Connection Benchmark..."
    
    local result
    result=$(ab -n 2000 -c 100 -q -r "$BASE_URL/../health" 2>&1)
    
    local rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
    local failed=$(echo "$result" | grep "Failed requests" | awk '{print $3}')
    
    if [ -z "$rps" ]; then
        log_failure "Could not parse concurrent benchmark results"
        return 1
    fi
    
    # Check error rate
    local total_requests=2000
    local error_rate=$(echo "scale=2; $failed * 100 / $total_requests" | bc)
    
    check_threshold "$error_rate" "$ERROR_RATE_THRESHOLD" "lte" "Concurrent Error Rate"
    
    echo "| Concurrent Error Rate | ${error_rate}% | ${ERROR_RATE_THRESHOLD}% | $(if (( $(echo "$error_rate <= $ERROR_RATE_THRESHOLD" | bc -l) )); then echo "✅"; else echo "❌"; fi) |" >> "$REPORT_FILE"
    
    log_info "Concurrent: ${rps} req/s, Error Rate: ${error_rate}%"
}

# ============================================
# Main Execution
# ============================================

main() {
    echo ""
    echo "============================================"
    echo "   StudioBook Performance Benchmarks"
    echo "============================================"
    echo ""
    
    # Check prerequisites
    if ! command -v ab &> /dev/null; then
        log_warning "Apache Bench (ab) not found. Installing..."
        sudo apt-get update && sudo apt-get install -y apache2-utils
    fi
    
    if ! command -v bc &> /dev/null; then
        log_warning "bc not found. Installing..."
        sudo apt-get install -y bc
    fi
    
    # Initialize report
    init_report
    
    # Check if server is running
    log_info "Checking server at $BASE_URL..."
    if ! curl -sf "$BASE_URL/../health" > /dev/null 2>&1; then
        log_failure "Server not reachable at $BASE_URL"
        echo ""
        echo "Please start the server first:"
        echo "  cd backend && php artisan serve"
        exit 1
    fi
    log_success "Server is reachable"
    
    # Run benchmarks
    echo ""
    log_info "Starting API benchmarks..."
    echo ""
    
    run_health_check_benchmark
    run_studios_benchmark
    run_search_benchmark
    run_concurrent_benchmark
    
    # Finalize report
    cat >> "$REPORT_FILE" << EOF

---

## Detailed Results

### Configuration

- **Requests per test:** 500-1000
- **Concurrent connections:** 25-100
- **Timeout:** 30s

### Thresholds Applied

| Metric | Warning | Critical |
|--------|---------|----------|
| Health Check P95 | <100ms | >200ms |
| Studios P95 | <200ms | >400ms |
| Search P95 | <300ms | >500ms |
| Error Rate | <1% | >5% |

---

## Summary

- **Tests Run:** $TESTS_RUN
- **Passed:** $TESTS_PASSED
- **Failed:** $FAILURES
- **Warnings:** $WARNINGS

$(if [ $FAILURES -eq 0 ]; then echo "✅ All benchmarks passed!"; else echo "❌ Some benchmarks failed. Review the results above."; fi)

---

*Generated by StudioBook Performance Benchmark Runner*
EOF
    
    # Print summary
    echo ""
    echo "============================================"
    echo "   Benchmark Summary"
    echo "============================================"
    echo ""
    echo "Tests Run:   $TESTS_RUN"
    echo "Passed:      $TESTS_PASSED"
    echo "Failed:      $FAILURES"
    echo "Warnings:    $WARNINGS"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo ""
    
    # CI mode - exit with error if failures
    if [ "$CI_MODE" = "--ci" ] && [ $FAILURES -gt 0 ]; then
        log_failure "Benchmark failed in CI mode"
        exit 1
    fi
    
    if [ $FAILURES -eq 0 ]; then
        echo -e "${GREEN}✅ All benchmarks passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some benchmarks failed${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
