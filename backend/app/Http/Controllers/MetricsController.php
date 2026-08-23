<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class MetricsController extends Controller
{
    /**
     * Get real-time performance overview
     */
    public function overview(Request $request): JsonResponse
    {
        $minutes = $request->get('minutes', 5);
        $metrics = $this->aggregateMetrics($minutes);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => [
                    'minutes' => $minutes,
                    'start' => now()->subMinutes($minutes)->toISOString(),
                    'end' => now()->toISOString(),
                ],
                'requests' => [
                    'total' => $metrics['total_requests'],
                    'per_minute' => round($metrics['total_requests'] / max($minutes, 1), 1),
                    'avg_response_time_ms' => $metrics['avg_response_time'],
                    'max_response_time_ms' => $metrics['max_response_time'],
                    'p95_response_time_ms' => $metrics['p95_response_time'],
                ],
                'queries' => [
                    'total' => $metrics['total_queries'],
                    'per_request' => $metrics['avg_query_count'],
                    'total_time_ms' => $metrics['total_query_time'],
                    'avg_time_ms' => $metrics['avg_query_time'],
                ],
                'slow_requests' => $metrics['slow_requests'],
                'health' => $this->assessHealth($metrics),
            ],
        ]);
    }

    /**
     * Get per-route performance breakdown
     */
    public function routes(Request $request): JsonResponse
    {
        $minutes = $request->get('minutes', 5);
        $routes = $this->getRouteMetrics($minutes);

        // Sort by average response time (slowest first)
        usort($routes, fn($a, $b) => $b['avg_time'] <=> $a['avg_time']);

        return response()->json([
            'success' => true,
            'data' => [
                'routes' => array_slice($routes, 0, 50),
                'total_routes' => count($routes),
            ],
        ]);
    }

    /**
     * Get slow requests log
     */
    public function slowRequests(Request $request): JsonResponse
    {
        $limit = min($request->get('limit', 50), 200);

        try {
            $logPath = storage_path('logs/performance.log');
            if (!file_exists($logPath)) {
                return response()->json([
                    'success' => true,
                    'data' => ['requests' => [], 'count' => 0],
                ]);
            }

            $lines = file($logPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $lines = array_reverse($lines); // Most recent first
            $lines = array_slice($lines, 0, $limit * 3); // Read more lines to parse

            $requests = [];
            foreach ($lines as $line) {
                if (str_contains($line, 'Slow request detected')) {
                    $requests[] = $this->parseSlowRequestLog($line);
                }
            }

            $requests = array_filter($requests); // Remove nulls
            $requests = array_slice($requests, 0, $limit);

            return response()->json([
                'success' => true,
                'data' => [
                    'requests' => $requests,
                    'count' => count($requests),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => true,
                'data' => ['requests' => [], 'count' => 0],
            ]);
        }
    }

    /**
     * Get slow queries log
     */
    public function slowQueries(Request $request): JsonResponse
    {
        $limit = min($request->get('limit', 50), 200);

        try {
            $logPath = storage_path('logs/performance.log');
            if (!file_exists($logPath)) {
                return response()->json([
                    'success' => true,
                    'data' => ['queries' => [], 'count' => 0],
                ]);
            }

            $content = file_get_contents($logPath);
            preg_match_all('/Slow query detected.*?sql": "(.*?)".*?time_ms": ([\d.]+)/s', $content, $matches);

            $queries = [];
            for ($i = 0; $i < min(count($matches[1]), $limit); $i++) {
                $queries[] = [
                    'sql' => $matches[1][$i] ?? '',
                    'time_ms' => (float) ($matches[2][$i] ?? 0),
                ];
            }

            // Sort by time (slowest first)
            usort($queries, fn($a, $b) => $b['time_ms'] <=> $a['time_ms']);

            return response()->json([
                'success' => true,
                'data' => [
                    'queries' => $queries,
                    'count' => count($queries),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => true,
                'data' => ['queries' => [], 'count' => 0],
            ]);
        }
    }

    /**
     * Get database performance metrics
     */
    public function database(): JsonResponse
    {
        $startTime = microtime(true);
        DB::select('SELECT 1');
        $pingTimeMs = round((microtime(true) - $startTime) * 1000, 2);

        // Get table sizes
        $driver = DB::connection()->getConfig('driver');
        $tables = [];

        try {
            if ($driver === 'sqlite') {
                $rows = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
                foreach ($rows as $row) {
                    $name = $row->name;
                    $count = DB::select("SELECT COUNT(*) as cnt FROM \"{$name}\"")[0]->cnt ?? 0;
                    $tables[$name] = ['rows' => $count];
                }
            }
        } catch (\Exception $e) {
            // Skip on error
        }

        $dbPath = DB::connection()->getConfig('database');
        $dbSize = file_exists($dbPath) ? round(filesize($dbPath) / 1024, 1) : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'driver' => $driver,
                'ping_time_ms' => $pingTimeMs,
                'database_size_kb' => $dbSize,
                'tables' => $tables,
            ],
        ]);
    }

    /**
     * Aggregate metrics from cache
     */
    protected function aggregateMetrics(int $minutes): array
    {
        $totalRequests = 0;
        $totalTime = 0;
        $totalQueries = 0;
        $totalQueryTime = 0;
        $maxTime = 0;
        $slowRequests = 0;
        $allTimes = [];

        for ($i = 0; $i < $minutes; $i++) {
            $key = 'metrics:requests:' . now()->subMinutes($i)->format('Y-m-d-H-i');
            $data = Cache::get($key);

            if ($data) {
                $totalRequests += $data['count'] ?? 0;
                $totalTime += $data['total_time'] ?? 0;
                $totalQueries += $data['total_queries'] ?? 0;
                $totalQueryTime += $data['total_query_time'] ?? 0;
                $maxTime = max($maxTime, $data['max_time'] ?? 0);
            }

            $slowKey = 'metrics:slow_requests:' . now()->subMinutes($i)->format('Y-m-d-H-i');
            $slowRequests += Cache::get($slowKey, 0);
        }

        $avgResponseTime = $totalRequests > 0 ? round($totalTime / $totalRequests, 2) : 0;
        $avgQueryCount = $totalRequests > 0 ? round($totalQueries / $totalRequests, 1) : 0;
        $avgQueryTime = $totalRequests > 0 ? round($totalQueryTime / $totalRequests, 2) : 0;

        return [
            'total_requests' => $totalRequests,
            'avg_response_time' => $avgResponseTime,
            'max_response_time' => $maxTime,
            'p95_response_time' => $maxTime * 0.9, // Simplified
            'total_queries' => $totalQueries,
            'avg_query_count' => $avgQueryCount,
            'total_query_time' => round($totalQueryTime, 2),
            'avg_query_time' => $avgQueryTime,
            'slow_requests' => $slowRequests,
        ];
    }

    /**
     * Get per-route metrics
     */
    protected function getRouteMetrics(int $minutes): array
    {
        $routeData = [];

        for ($i = 0; $i < $minutes; $i++) {
            $minute = now()->subMinutes($i)->format('Y-m-d-H-i');
            $prefix = 'metrics:route:' . $minute;

            // Use Cache::get with pattern - scan keys
            try {
                $keys = Cache::store('file')->getStore()->getDirectory();
            } catch (\Exception $e) {
                // If we can't scan, return empty
            }
        }

        return $routeData;
    }

    /**
     * Assess overall health
     */
    protected function assessHealth(array $metrics): array
    {
        $config = config('performance.thresholds');
        $status = 'healthy';
        $issues = [];

        if ($metrics['avg_response_time'] > $config['response_time']['critical']) {
            $status = 'critical';
            $issues[] = "Avg response time ({$metrics['avg_response_time']}ms) exceeds critical threshold";
        } elseif ($metrics['avg_response_time'] > $config['response_time']['warning']) {
            $status = max($status, 'warning');
            $issues[] = "Avg response time ({$metrics['avg_response_time']}ms) exceeds warning threshold";
        }

        if ($metrics['avg_query_time'] > $config['query_time']['critical']) {
            $status = 'critical';
            $issues[] = "Avg query time ({$metrics['avg_query_time']}ms) exceeds critical threshold";
        }

        if ($metrics['avg_query_count'] > $config['query_count']['warning']) {
            $status = max($status, 'warning');
            $issues[] = "Avg query count ({$metrics['avg_query_count']}) exceeds threshold";
        }

        if ($metrics['slow_requests'] > 10) {
            $status = max($status, 'warning');
            $issues[] = "{$metrics['slow_requests']} slow requests in period";
        }

        return [
            'status' => $status,
            'issues' => $issues,
        ];
    }

    /**
     * Parse slow request log line
     */
    protected function parseSlowRequestLog(string $line): ?array
    {
        try {
            preg_match('/"method": "(.*?)"/', $line, $method);
            preg_match('/"path": "(.*?)"/', $line, $path);
            preg_match('/"response_time_ms": ([\d.]+)/', $line, $time);
            preg_match('/"query_count": (\d+)/', $line, $queries);
            preg_match('/"query_time_ms": ([\d.]+)/', $line, $queryTime);

            return [
                'method' => $method[1] ?? 'UNKNOWN',
                'path' => $path[1] ?? '/',
                'response_time_ms' => (float) ($time[1] ?? 0),
                'query_count' => (int) ($queries[1] ?? 0),
                'query_time_ms' => (float) ($queryTime[1] ?? 0),
            ];
        } catch (\Exception $e) {
            return null;
        }
    }
}
