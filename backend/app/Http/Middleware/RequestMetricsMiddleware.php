<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class RequestMetricsMiddleware
{
    /**
     * Slow query threshold in milliseconds
     */
    protected int $slowQueryThreshold;

    /**
     * Slow request threshold in milliseconds
     */
    protected int $slowRequestThreshold;

    public function __construct()
    {
        $this->slowQueryThreshold = (int) config('performance.slow_query_threshold_ms', 100);
        $this->slowRequestThreshold = (int) config('performance.slow_request_threshold_ms', 500);
    }

    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);
        $startMemory = memory_get_usage();

        // Enable query logging if not already enabled
        $wasLoggingEnabled = DB::pretending();
        DB::enableQueryLog();

        $response = $next($request);

        $endTime = microtime(true);
        $endMemory = memory_get_usage();

        // Calculate metrics
        $responseTimeMs = round(($endTime - $startTime) * 1000, 2);
        $memoryUsedBytes = $endMemory - $startMemory;
        $memoryUsedMB = round($memoryUsedBytes / 1024 / 1024, 2);

        // Get query stats
        $queries = DB::getQueryLog();
        $queryCount = count($queries);
        $totalQueryTimeMs = 0;
        $slowQueries = [];

        foreach ($queries as $query) {
            $queryTimeMs = round(($query['time'] ?? 0) * 1000, 2);
            $totalQueryTimeMs += $queryTimeMs;

            if ($queryTimeMs >= $this->slowQueryThreshold) {
                $slowQueries[] = [
                    'sql' => $this->formatSql($query['query'] ?? ''),
                    'bindings' => $query['bindings'] ?? [],
                    'time_ms' => $queryTimeMs,
                ];
            }
        }

        $totalQueryTimeMs = round($totalQueryTimeMs, 2);

        // Disable query log to prevent memory leak
        DB::disableQueryLog();

        // Store metrics in request for access by other code
        $request->attributes->set('_metrics', [
            'response_time_ms' => $responseTimeMs,
            'query_count' => $queryCount,
            'query_time_ms' => $totalQueryTimeMs,
            'memory_mb' => $memoryUsedMB,
            'slow_queries' => $slowQueries,
        ]);

        // Add performance headers
        $response->headers->set('X-Response-Time', $responseTimeMs . 'ms');
        $response->headers->set('X-Query-Count', (string) $queryCount);
        $response->headers->set('X-Query-Time', $totalQueryTimeMs . 'ms');

        // Store metrics for aggregation
        $this->storeMetrics($request, $responseTimeMs, $queryCount, $totalQueryTimeMs);

        // Log slow requests
        if ($responseTimeMs >= $this->slowRequestThreshold) {
            $this->logSlowRequest($request, $responseTimeMs, $queryCount, $totalQueryTimeMs, $slowQueries);
        }

        // Log slow queries
        if (!empty($slowQueries)) {
            $this->logSlowQueries($slowQueries, $request);
        }

        return $response;
    }

    /**
     * Store metrics for aggregation and monitoring
     */
    protected function storeMetrics(Request $request, float $responseTimeMs, int $queryCount, float $queryTimeMs): void
    {
        try {
            $route = $request->route()?->getAction('as') ?? $request->path();
            $method = $request->method();
            $statusCode = null; // We don't have response here easily, skip for now
            $minuteKey = now()->format('Y-m-d-H-i');

            // Store in cache for real-time monitoring
            $metricsKey = "metrics:requests:{$minuteKey}";
            $metrics = Cache::get($metricsKey, [
                'count' => 0,
                'total_time' => 0,
                'total_queries' => 0,
                'total_query_time' => 0,
                'max_time' => 0,
                'errors' => 0,
            ]);

            $metrics['count']++;
            $metrics['total_time'] += $responseTimeMs;
            $metrics['total_queries'] += $queryCount;
            $metrics['total_query_time'] += $queryTimeMs;
            $metrics['max_time'] = max($metrics['max_time'], $responseTimeMs);

            Cache::put($metricsKey, $metrics, 3600);

            // Store per-route metrics
            $routeKey = "metrics:route:{$method}:{$route}:{$minuteKey}";
            $routeMetrics = Cache::get($routeKey, [
                'count' => 0,
                'total_time' => 0,
                'max_time' => 0,
                'avg_time' => 0,
            ]);

            $routeMetrics['count']++;
            $routeMetrics['total_time'] += $responseTimeMs;
            $routeMetrics['max_time'] = max($routeMetrics['max_time'], $responseTimeMs);
            $routeMetrics['avg_time'] = round($routeMetrics['total_time'] / $routeMetrics['count'], 2);

            Cache::put($routeKey, $routeMetrics, 3600);

            // Track slow requests count
            if ($responseTimeMs >= $this->slowRequestThreshold) {
                $slowKey = "metrics:slow_requests:{$minuteKey}";
                $slowCount = Cache::get($slowKey, 0);
                Cache::put($slowKey, $slowCount + 1, 3600);
            }
        } catch (\Exception $e) {
            // Don't let metrics tracking break the request
        }
    }

    /**
     * Log slow request to file
     */
    protected function logSlowRequest(
        Request $request,
        float $responseTimeMs,
        int $queryCount,
        float $queryTimeMs,
        array $slowQueries
    ): void {
        $context = [
            'method' => $request->method(),
            'path' => $request->path(),
            'route' => $request->route()?->getAction('as') ?? 'unknown',
            'response_time_ms' => $responseTimeMs,
            'query_count' => $queryCount,
            'query_time_ms' => $queryTimeMs,
            'slow_queries' => $slowQueries,
            'ip' => $request->ip(),
            'user_id' => $request->user()?->id,
        ];

        Log::channel('performance')->warning('Slow request detected', $context);
    }

    /**
     * Log slow queries
     */
    protected function logSlowQueries(array $slowQueries, Request $request): void
    {
        foreach ($slowQueries as $query) {
            Log::channel('performance')->warning('Slow query detected', [
                'sql' => $query['sql'],
                'time_ms' => $query['time_ms'],
                'route' => $request->route()?->getAction('as') ?? $request->path(),
            ]);
        }
    }

    /**
     * Format SQL for readability
     */
    protected function formatSql(string $sql): string
    {
        // Replace multiple spaces with single space
        $sql = preg_replace('/\s+/', ' ', $sql);
        // Trim
        $sql = trim($sql);
        // Truncate if too long
        if (strlen($sql) > 500) {
            $sql = substr($sql, 0, 500) . '...';
        }
        return $sql;
    }
}
