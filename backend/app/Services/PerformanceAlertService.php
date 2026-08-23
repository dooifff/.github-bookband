<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class PerformanceAlertService
{
    /**
     * Alert thresholds configuration
     */
    protected array $thresholds = [
        'cpu' => [
            'warning' => 70,
            'critical' => 90,
        ],
        'memory' => [
            'warning' => 70,
            'critical' => 85,
        ],
        'disk' => [
            'warning' => 80,
            'critical' => 90,
        ],
        'response_time' => [
            'warning' => 200,  // ms
            'critical' => 500, // ms
        ],
        'error_rate' => [
            'warning' => 1,   // %
            'critical' => 5,  // %
        ],
        'queue_failed' => [
            'warning' => 10,
            'critical' => 50,
        ],
        'database_connections' => [
            'warning' => 80,  // percentage
            'critical' => 95,
        ],
    ];

    /**
     * Alert history storage key
     */
    protected string $alertHistoryKey = 'performance:alerts:history';

    /**
     * Cooldown period between same alerts (in seconds)
     */
    protected int $cooldownPeriod = 300; // 5 minutes

    /**
     * Check metrics and generate alerts
     */
    public function checkAndAlert(array $metrics): array
    {
        $alerts = [];
        $currentAlerts = $this->getCurrentAlerts();

        // Check CPU
        if (isset($metrics['cpu_usage'])) {
            $alert = $this->checkMetric('cpu', $metrics['cpu_usage'], $currentAlerts);
            if ($alert) $alerts[] = $alert;
        }

        // Check Memory
        if (isset($metrics['memory_usage'])) {
            $alert = $this->checkMetric('memory', $metrics['memory_usage'], $currentAlerts);
            if ($alert) $alerts[] = $alert;
        }

        // Check Disk
        if (isset($metrics['disk_usage'])) {
            $alert = $this->checkMetric('disk', $metrics['disk_usage'], $currentAlerts);
            if ($alert) $alerts[] = $alert;
        }

        // Check Response Time
        if (isset($metrics['avg_response_time'])) {
            $alert = $this->checkMetric('response_time', $metrics['avg_response_time'], $currentAlerts);
            if ($alert) $alerts[] = $alert;
        }

        // Check Error Rate
        if (isset($metrics['error_rate'])) {
            $alert = $this->checkMetric('error_rate', $metrics['error_rate'], $currentAlerts);
            if ($alert) $alerts[] = $alert;
        }

        // Check Failed Queue Jobs
        if (isset($metrics['queue_failed'])) {
            $alert = $this->checkMetric('queue_failed', $metrics['queue_failed'], $currentAlerts);
            if ($alert) $alerts[] = $alert;
        }

        // Store new alerts
        if (!empty($alerts)) {
            $this->storeAlerts($alerts);
            $this->sendNotifications($alerts);
        }

        return $alerts;
    }

    /**
     * Check a single metric against thresholds
     */
    protected function checkMetric(string $metric, float $value, array $currentAlerts): ?array
    {
        if (!isset($this->thresholds[$metric])) {
            return null;
        }

        $thresholds = $this->thresholds[$metric];
        $severity = null;
        $message = '';

        // Determine severity
        if ($value >= $thresholds['critical']) {
            $severity = 'critical';
            $message = $this->getCriticalMessage($metric, $value, $thresholds['critical']);
        } elseif ($value >= $thresholds['warning']) {
            $severity = 'warning';
            $message = $this->getWarningMessage($metric, $value, $thresholds['warning']);
        } else {
            // Value is OK - check if we need to send recovery alert
            $existingAlert = $this->findExistingAlert($metric, $currentAlerts);
            if ($existingAlert) {
                return $this->createRecoveryAlert($metric, $value, $existingAlert);
            }
            return null;
        }

        // Check cooldown
        if ($this->isOnCooldown($metric, $severity)) {
            return null;
        }

        return [
            'id' => uniqid('alert_'),
            'metric' => $metric,
            'severity' => $severity,
            'message' => $message,
            'value' => $value,
            'threshold' => $thresholds[$severity],
            'timestamp' => now()->toISOString(),
            'status' => 'active',
        ];
    }

    /**
     * Get critical threshold message
     */
    protected function getCriticalMessage(string $metric, float $value, float $threshold): string
    {
        $messages = [
            'cpu' => "🔴 CRITICAL: CPU usage at {$value}% (threshold: {$threshold}%)",
            'memory' => "🔴 CRITICAL: Memory usage at {$value}% (threshold: {$threshold}%)",
            'disk' => "🔴 CRITICAL: Disk usage at {$value}% (threshold: {$threshold}%)",
            'response_time' => "🔴 CRITICAL: Response time at {$value}ms (threshold: {$threshold}ms)",
            'error_rate' => "🔴 CRITICAL: Error rate at {$value}% (threshold: {$threshold}%)",
            'queue_failed' => "🔴 CRITICAL: {$value} failed jobs (threshold: {$threshold})",
        ];

        return $messages[$metric] ?? "🔴 CRITICAL: {$metric} at {$value} (threshold: {$threshold})";
    }

    /**
     * Get warning threshold message
     */
    protected function getWarningMessage(string $metric, float $value, float $threshold): string
    {
        $messages = [
            'cpu' => "🟡 WARNING: CPU usage at {$value}% (threshold: {$threshold}%)",
            'memory' => "🟡 WARNING: Memory usage at {$value}% (threshold: {$threshold}%)",
            'disk' => "🟡 WARNING: Disk usage at {$value}% (threshold: {$threshold}%)",
            'response_time' => "🟡 WARNING: Response time at {$value}ms (threshold: {$threshold}ms)",
            'error_rate' => "🟡 WARNING: Error rate at {$value}% (threshold: {$threshold}%)",
            'queue_failed' => "🟡 WARNING: {$value} failed jobs (threshold: {$threshold})",
        ];

        return $messages[$metric] ?? "🟡 WARNING: {$metric} at {$value} (threshold: {$threshold})";
    }

    /**
     * Create recovery alert
     */
    protected function createRecoveryAlert(string $metric, float $value, array $existingAlert): array
    {
        return [
            'id' => uniqid('alert_recovery_'),
            'metric' => $metric,
            'severity' => 'info',
            'message' => "🟢 RECOVERED: {$metric} back to normal at {$value}",
            'value' => $value,
            'threshold' => $existingAlert['threshold'] ?? 0,
            'timestamp' => now()->toISOString(),
            'status' => 'resolved',
            'resolved_at' => now()->toISOString(),
        ];
    }

    /**
     * Find existing active alert for metric
     */
    protected function findExistingAlert(string $metric, array $currentAlerts): ?array
    {
        foreach ($currentAlerts as $alert) {
            if ($alert['metric'] === $metric && $alert['status'] === 'active') {
                return $alert;
            }
        }
        return null;
    }

    /**
     * Check if metric is on cooldown
     */
    protected function isOnCooldown(string $metric, string $severity): bool
    {
        $cooldownKey = "performance:cooldown:{$metric}:{$severity}";
        return Cache::has($cooldownKey);
    }

    /**
     * Set cooldown for metric
     */
    protected function setCooldown(string $metric, string $severity): void
    {
        $cooldownKey = "performance:cooldown:{$metric}:{$severity}";
        Cache::put($cooldownKey, true, $this->cooldownPeriod);
    }

    /**
     * Get current active alerts
     */
    public function getCurrentAlerts(): array
    {
        return Cache::get($this->alertHistoryKey, []);
    }

    /**
     * Store alerts in cache
     */
    protected function storeAlerts(array $alerts): void
    {
        $currentAlerts = $this->getCurrentAlerts();

        foreach ($alerts as $alert) {
            // Add to history
            $currentAlerts[] = $alert;

            // Set cooldown
            if ($alert['severity'] !== 'info') {
                $this->setCooldown($alert['metric'], $alert['severity']);
            }

            // Mark resolved if recovery
            if ($alert['status'] === 'resolved') {
                $this->resolveAlert($alert['metric']);
            }
        }

        // Keep only last 100 alerts
        $currentAlerts = array_slice($currentAlerts, -100);

        Cache::put($this->alertHistoryKey, $currentAlerts, 86400); // 24 hours
    }

    /**
     * Mark alert as resolved
     */
    protected function resolveAlert(string $metric): void
    {
        $alerts = $this->getCurrentAlerts();

        foreach ($alerts as &$alert) {
            if ($alert['metric'] === $metric && $alert['status'] === 'active') {
                $alert['status'] = 'resolved';
                $alert['resolved_at'] = now()->toISOString();
            }
        }

        Cache::put($this->alertHistoryKey, $alerts, 86400);
    }

    /**
     * Send notifications for alerts
     */
    protected function sendNotifications(array $alerts): void
    {
        foreach ($alerts as $alert) {
            // Log to application log
            Log::channel('performance')->warning($alert['message'], [
                'metric' => $alert['metric'],
                'severity' => $alert['severity'],
                'value' => $alert['value'],
            ]);

            // Send to configured webhooks
            $this->sendWebhook($alert);

            // Send email for critical alerts
            if ($alert['severity'] === 'critical') {
                $this->sendEmailAlert($alert);
            }
        }
    }

    /**
     * Send webhook notification
     */
    protected function sendWebhook(array $alert): void
    {
        $webhookUrls = config('performance.webhooks', []);

        foreach ($webhookUrls as $url) {
            try {
                Http::timeout(5)->post($url, [
                    'text' => $alert['message'],
                    'alert' => $alert,
                    'source' => 'studiobook-performance',
                ]);
            } catch (\Exception $e) {
                Log::error('Failed to send performance webhook', [
                    'url' => $url,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }

    /**
     * Send email alert for critical issues
     */
    protected function sendEmailAlert(array $alert): void
    {
        // In production, use Laravel Mailable
        Log::critical('Performance Alert Email', [
            'to' => config('performance.alert_email', 'admin@studiobook.com'),
            'alert' => $alert,
        ]);
    }

    /**
     * Get alert statistics
     */
    public function getStatistics(): array
    {
        $alerts = $this->getCurrentAlerts();
        $now = now();

        $stats = [
            'total' => count($alerts),
            'active' => 0,
            'resolved' => 0,
            'critical' => 0,
            'warning' => 0,
            'by_metric' => [],
            'last_24h' => 0,
            'last_7d' => 0,
        ];

        foreach ($alerts as $alert) {
            // Count by status
            if ($alert['status'] === 'active') {
                $stats['active']++;
            } else {
                $stats['resolved']++;
            }

            // Count by severity
            if (isset($stats[$alert['severity']])) {
                $stats[$alert['severity']]++;
            }

            // Count by metric
            $metric = $alert['metric'];
            if (!isset($stats['by_metric'][$metric])) {
                $stats['by_metric'][$metric] = ['total' => 0, 'critical' => 0, 'warning' => 0];
            }
            $stats['by_metric'][$metric]['total']++;
            if (isset($stats['by_metric'][$metric][$alert['severity']])) {
                $stats['by_metric'][$metric][$alert['severity']]++;
            }

            // Time-based counts
            $alertTime = \Carbon\Carbon::parse($alert['timestamp']);
            if ($alertTime->diffInHours($now) <= 24) {
                $stats['last_24h']++;
            }
            if ($alertTime->diffInDays($now) <= 7) {
                $stats['last_7d']++;
            }
        }

        return $stats;
    }

    /**
     * Get alert history with pagination
     */
    public function getHistory(int $page = 1, int $perPage = 20, ?string $severity = null): array
    {
        $alerts = $this->getCurrentAlerts();

        // Filter by severity if specified
        if ($severity) {
            $alerts = array_filter($alerts, fn($a) => $a['severity'] === $severity);
        }

        // Sort by timestamp (newest first)
        usort($alerts, fn($a, $b) => strtotime($b['timestamp']) - strtotime($a['timestamp']));

        // Paginate
        $total = count($alerts);
        $offset = ($page - 1) * $perPage;
        $items = array_slice($alerts, $offset, $perPage);

        return [
            'data' => $items,
            'meta' => [
                'total' => $total,
                'per_page' => $perPage,
                'current_page' => $page,
                'last_page' => ceil($total / $perPage),
            ],
        ];
    }

    /**
     * Clear alert history
     */
    public function clearHistory(): void
    {
        Cache::forget($this->alertHistoryKey);
    }

    /**
     * Get configured thresholds
     */
    public function getThresholds(): array
    {
        return $this->thresholds;
    }

    /**
     * Update thresholds
     */
    public function updateThresholds(array $thresholds): void
    {
        $this->thresholds = array_merge($this->thresholds, $thresholds);
    }
}
