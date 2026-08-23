# Performance Test Report

## Summary

| Metric | Value | Status |
|--------|-------|--------|
| **Test Date** | {{DATE}} | - |
| **Commit** | {{COMMIT}} | - |
| **Total Tests** | {{TOTAL_TESTS}} | - |
| **Passed** | {{PASSED}} | ✅ |
| **Failed** | {{FAILED}} | {{FAIL_STATUS}} |

## Response Time Analysis

### Health Check
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Avg Response Time | {{HEALTH_AVG}}ms | <100ms | {{HEALTH_STATUS}} |
| 95th Percentile | {{HEALTH_P95}}ms | <150ms | {{HEALTH_P95_STATUS}} |
| 99th Percentile | {{HEALTH_P99}}ms | <200ms | {{HEALTH_P99_STATUS}} |
| Requests/sec | {{HEALTH_RPS}} | >1000 | {{HEALTH_RPS_STATUS}} |

### Studios List
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Avg Response Time | {{STUDIOS_AVG}}ms | <200ms | {{STUDIOS_STATUS}} |
| 95th Percentile | {{STUDIOS_P95}}ms | <300ms | {{STUDIOS_P95_STATUS}} |
| 99th Percentile | {{STUDIOS_P99}}ms | <400ms | {{STUDIOS_P99_STATUS}} |
| Requests/sec | {{STUDIOS_RPS}} | >500 | {{STUDIOS_RPS_STATUS}} |

### Studio Search
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Avg Response Time | {{SEARCH_AVG}}ms | <300ms | {{SEARCH_STATUS}} |
| 95th Percentile | {{SEARCH_P95}}ms | <450ms | {{SEARCH_P95_STATUS}} |
| 99th Percentile | {{SEARCH_P99}}ms | <600ms | {{SEARCH_P99_STATUS}} |
| Requests/sec | {{SEARCH_RPS}} | >400 | {{SEARCH_RPS_STATUS}} |

### Authenticated Endpoints
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Avg Response Time | {{AUTH_AVG}}ms | <500ms | {{AUTH_STATUS}} |
| 95th Percentile | {{AUTH_P95}}ms | <750ms | {{AUTH_P95_STATUS}} |
| 99th Percentile | {{AUTH_P99}}ms | <1000ms | {{AUTH_P99_STATUS}} |
| Requests/sec | {{AUTH_RPS}} | >100 | {{AUTH_RPS_STATUS}} |

## Throughput Analysis

| Endpoint | Requests/sec | Total Requests | Concurrent Users | Duration |
|----------|--------------|----------------|------------------|----------|
| Health Check | {{HEALTH_RPS}} | 1000 | 50 | {{HEALTH_DURATION}}s |
| Studios List | {{STUDIOS_RPS}} | 500 | 25 | {{STUDIOS_DURATION}}s |
| Studio Search | {{SEARCH_RPS}} | 500 | 25 | {{SEARCH_DURATION}}s |
| Auth Login | {{LOGIN_RPS}} | 200 | 10 | {{LOGIN_DURATION}}s |

## Error Analysis

| Error Type | Count | Percentage | Affected Endpoints |
|------------|-------|------------|-------------------|
| 4xx Errors | {{ERROR_4XX}} | {{ERROR_4XX_PCT}}% | {{ERROR_4XX_ENDPOINTS}} |
| 5xx Errors | {{ERROR_5XX}} | {{ERROR_5XX_PCT}}% | {{ERROR_5XX_ENDPOINTS}} |
| Timeouts | {{TIMEOUTS}} | {{TIMEOUTS_PCT}}% | {{TIMEOUTS_ENDPOINTS}} |

## Database Performance

| Query Type | Avg Time | Max Time | Threshold | Status |
|------------|----------|----------|-----------|--------|
| Simple SELECT | {{DB_SIMPLE_AVG}}ms | {{DB_SIMPLE_MAX}}ms | <100ms | {{DB_SIMPLE_STATUS}} |
| Complex JOIN | {{DB_JOIN_AVG}}ms | {{DB_JOIN_MAX}}ms | <500ms | {{DB_JOIN_STATUS}} |
| Search Query | {{DB_SEARCH_AVG}}ms | {{DB_SEARCH_MAX}}ms | <300ms | {{DB_SEARCH_STATUS}} |

## Resource Usage

| Resource | Average | Peak | Limit | Status |
|----------|---------|------|-------|--------|
| CPU | {{CPU_AVG}}% | {{CPU_PEAK}}% | 80% | {{CPU_STATUS}} |
| Memory | {{MEMORY_AVG}}MB | {{MEMORY_PEAK}}MB | 1GB | {{MEMORY_STATUS}} |
| Connections | {{CONNECTIONS_AVG}} | {{CONNECTIONS_PEAK}} | 200 | {{CONNECTIONS_STATUS}} |

## Regression Analysis

### Comparison with Previous Run
| Metric | Current | Previous | Change | Status |
|--------|---------|----------|--------|--------|
| Avg Response Time | {{CURRENT_AVG}}ms | {{PREVIOUS_AVG}}ms | {{AVG_CHANGE}} | {{AVG_STATUS}} |
| Requests/sec | {{CURRENT_RPS}} | {{PREVIOUS_RPS}} | {{RPS_CHANGE}} | {{RPS_STATUS}} |
| Error Rate | {{CURRENT_ERRORS}}% | {{PREVIOUS_ERRORS}}% | {{ERRORS_CHANGE}} | {{ERRORS_STATUS}} |

### Performance Trends
- Response time trend: {{TREND_DIRECTION}} ({{TREND_PERCENTAGE}}% over {{TREND_PERIOD}})
- Throughput trend: {{THROUGHPUT_DIRECTION}} ({{THROUGHPUT_PERCENTAGE}}% over {{THROUGHPUT_PERIOD}})
- Error rate trend: {{ERROR_TREND_DIRECTION}} ({{ERROR_TREND_PERCENTAGE}}% over {{ERROR_TREND_PERIOD}})

## Recommendations

### High Priority
{{HIGH_PRIORITY_RECOMMENDATIONS}}

### Medium Priority
{{MEDIUM_PRIORITY_RECOMMENDATIONS}}

### Low Priority
{{LOW_PRIORITY_RECOMMENDATIONS}}

## Conclusion

{{CONCLUSION}}

---

**Report Generated:** {{GENERATED_DATE}}
**Test Environment:** {{TEST_ENVIRONMENT}}
**Version:** {{VERSION}}
