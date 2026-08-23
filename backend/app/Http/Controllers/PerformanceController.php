<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class PerformanceController extends Controller
{
    /**
     * Get system performance overview
     */
    public function overview()
    {
        $startTime = microtime(true);

        // Server metrics
        $serverMetrics = $this->getServerMetrics();

        // Database metrics
        $dbMetrics = $this->getDatabaseMetrics();

        // Application metrics
        $appMetrics = $this->getApplicationMetrics();

        // Response time
        $responseTime = round((microtime(true) - $startTime) * 1000, 2);

        return response()->json([
            'success' => true,
            'data' => [
                'server' => $serverMetrics,
                'database' => $dbMetrics,
                'application' => $appMetrics,
                'response_time_ms' => $responseTime,
                'timestamp' => now()->toISOString(),
            ],
        ]);
    }

    /**
     * Get server metrics (CPU, Memory, Disk)
     */
    public function serverMetrics()
    {
        $metrics = $this->getServerMetrics();

        return response()->json([
            'success' => true,
            'data' => $metrics,
        ]);
    }

    /**
     * Get database performance metrics
     */
    public function databaseMetrics()
    {
        $metrics = $this->getDatabaseMetrics();

        return response()->json([
            'success' => true,
            'data' => $metrics,
        ]);
    }

    /**
     * Get API performance metrics
     */
    public function apiMetrics()
    {
        $metrics = $this->getApplicationMetrics();

        return response()->json([
            'success' => true,
            'data' => $metrics,
        ]);
    }

    /**
     * Get real-time performance data (WebSocket-ready)
     */
    public function realtime()
    {
        // Store current metrics in cache for real-time access
        $metrics = [
            'server' => $this->getServerMetrics(),
            'database' => $this->getDatabaseMetrics(),
            'timestamp' => now()->toISOString(),
        ];

        Cache::put('performance:realtime', $metrics, 60);

        return response()->json([
            'success' => true,
            'data' => $metrics,
        ]);
    }

    /**
     * Get performance history
     */
    public function history(Request $request)
    {
        $hours = $request->get('hours', 24);

        // Generate historical data (in production, store in database)
        $history = [];
        $now = now();

        for ($i = $hours; $i >= 0; $i--) {
            $timestamp = $now->copy()->subHours($i);
            $history[] = [
                'timestamp' => $timestamp->toISOString(),
                'cpu' => rand(20, 80),
                'memory' => rand(40, 75),
                'response_time' => rand(50, 200),
                'requests_per_second' => rand(50, 200),
                'active_users' => rand(10, 100),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'history' => $history,
                'period_hours' => $hours,
            ],
        ]);
    }

    /**
     * Get performance alerts
     */
    public function alerts()
    {
        $alerts = [];
        $metrics = $this->getServerMetrics();

        // CPU alert
        if ($metrics['cpu_usage'] > 80) {
            $alerts[] = [
                'type' => 'warning',
                'message' => "High CPU usage: {$metrics['cpu_usage']}%",
                'metric' => 'cpu',
                'value' => $metrics['cpu_usage'],
                'threshold' => 80,
                'timestamp' => now()->toISOString(),
            ];
        }

        // Memory alert
        if ($metrics['memory_usage'] > 85) {
            $alerts[] = [
                'type' => 'critical',
                'message' => "High memory usage: {$metrics['memory_usage']}%",
                'metric' => 'memory',
                'value' => $metrics['memory_usage'],
                'threshold' => 85,
                'timestamp' => now()->toISOString(),
            ];
        }

        // Disk alert
        if ($metrics['disk_usage'] > 90) {
            $alerts[] = [
                'type' => 'critical',
                'message' => "High disk usage: {$metrics['disk_usage']}%",
                'metric' => 'disk',
                'value' => $metrics['disk_usage'],
                'threshold' => 90,
                'timestamp' => now()->toISOString(),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'alerts' => $alerts,
                'count' => count($alerts),
                'has_critical' => collect($alerts)->contains('type', 'critical'),
            ],
        ]);
    }

    /**
     * Get server metrics
     */
    private function getServerMetrics(): array
    {
        // CPU usage
        $cpuUsage = $this->getCpuUsage();

        // Memory usage
        $memoryTotal = memory_get_usage(true);
        $memoryUsed = memory_get_usage(false);
        $memoryPercentage = round(($memoryUsed / $memoryTotal) * 100, 2);

        // PHP memory limit
        $memoryLimit = ini_get('memory_limit');

        // Disk usage
        $diskTotal = disk_total_space('/');
        $diskFree = disk_free_space('/');
        $diskUsed = $diskTotal - $diskFree;
        $diskPercentage = round(($diskUsed / $diskTotal) * 100, 2);

        // Uptime
        $uptime = $this->getUptime();

        return [
            'cpu_usage' => $cpuUsage,
            'memory' => [
                'used' => $this->formatBytes($memoryUsed),
                'total' => $this->formatBytes($memoryTotal),
                'percentage' => $memoryPercentage,
                'php_limit' => $memoryLimit,
            ],
            'disk' => [
                'used' => $this->formatBytes($diskUsed),
                'total' => $this->formatBytes($diskTotal),
                'free' => $this->formatBytes($diskFree),
                'percentage' => $diskPercentage,
            ],
            'uptime' => $uptime,
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'environment' => app()->environment(),
        ];
    }

    /**
     * Get database metrics
     */
    private function getDatabaseMetrics(): array
    {
        $startTime = microtime(true);

        // Test query performance
        DB::select('SELECT 1');
        $queryTime = round((microtime(true) - $startTime) * 1000, 2);

        // Get connection info
        $connection = DB::connection();
        $config = $connection->getConfig();

        // Count tables (SQLite + MySQL compatible)
        $tableCount = 0;
        try {
            $driver = $config['driver'] ?? 'unknown';
            if ($driver === 'sqlite') {
                $tables = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
            } else {
                $tables = DB::select('SHOW TABLES');
            }
            $tableCount = count($tables);
        } catch (\Exception $e) {
            $tableCount = -1;
        }

        // Database size
        $dbName = $config['database'] ?? 'unknown';
        $dbSize = $this->getDatabaseSize($dbName);

        return [
            'driver' => $config['driver'] ?? 'unknown',
            'database' => $dbName,
            'query_time_ms' => $queryTime,
            'table_count' => $tableCount,
            'size' => $dbSize,
            'status' => 'connected',
        ];
    }

    /**
     * Get application metrics
     */
    private function getApplicationMetrics(): array
    {
        $requestCount = Cache::get('metrics:request_count', 0);
        $errorCount = Cache::get('metrics:error_count', 0);
        $avgResponseTime = Cache::get('metrics:avg_response_time', 0);
        $activeUsers = Cache::get('metrics:active_users', 0);

        return [
            'requests' => [
                'total' => $requestCount,
                'errors' => $errorCount,
                'error_rate' => $requestCount > 0
                    ? round(($errorCount / $requestCount) * 100, 2)
                    : 0,
            ],
            'response_time' => [
                'average_ms' => $avgResponseTime,
            ],
            'active_users' => $activeUsers,
            'process' => [
                'pid' => getmypid(),
                'memory_peak' => $this->formatBytes(memory_get_peak_usage()),
            ],
        ];
    }

    private function getCpuUsage(): float
    {
        if (PHP_OS_FAMILY === 'Linux') {
            $load = sys_getloadavg();
            if ($load !== false) {
                $cores = $this->getCpuCores();
                return round(($load[0] / $cores) * 100, 2);
            }
        }
        return 0;
    }

    private function getCpuCores(): int
    {
        if (PHP_OS_FAMILY === 'Linux') {
            return (int) shell_exec('nproc') ?: 1;
        }
        return 1;
    }

    private function getUptime(): string
    {
        if (PHP_OS_FAMILY !== 'Linux') {
            return 'N/A';
        }
        $uptime = @file_get_contents('/proc/uptime');
        if ($uptime === false) {
            return 'N/A';
        }
        $parts = explode(' ', $uptime);
        $seconds = (int) $parts[0];
        $days = floor($seconds / 86400);
        $hours = floor(($seconds % 86400) / 3600);
        $minutes = floor(($seconds % 3600) / 60);
        return "{$days}d {$hours}h {$minutes}m";
    }

    private function getDatabaseSize(string $database): string
    {
        try {
            $driver = DB::connection()->getConfig('driver');
            if ($driver === 'sqlite') {
                $path = DB::connection()->getConfig('database');
                if (file_exists($path)) {
                    return $this->formatBytes(filesize($path));
                }
            }
        } catch (\Exception $e) {
            // Fallback
        }
        return 'N/A';
    }

    private function formatBytes(int $bytes, int $precision = 2): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);
        return round($bytes, $precision) . ' ' . $units[$pow];
    }
}
