<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class PerformanceHistoryService
{
    /**
     * Storage keys
     */
    protected string $historyKey = 'performance:history';
    protected string $snapshotsKey = 'performance:snapshots';

    /**
     * Store a performance snapshot
     */
    public function storeSnapshot(array $metrics): array
    {
        $snapshot = [
            'id' => uniqid('snap_'),
            'timestamp' => now()->toISOString(),
            'metrics' => $metrics,
            'summary' => $this->calculateSummary($metrics),
        ];

        // Store in cache (keep last 1000 snapshots)
        $history = Cache::get($this->historyKey, []);
        $history[] = $snapshot;
        $history = array_slice($history, -1000);
        Cache::put($this->historyKey, $history, 86400 * 30); // 30 days

        // Store daily summary
        $this->storeDailySummary($snapshot);

        return $snapshot;
    }

    /**
     * Calculate summary from metrics
     */
    protected function calculateSummary(array $metrics): array
    {
        return [
            'cpu' => $metrics['cpu_usage'] ?? 0,
            'memory' => $metrics['memory_usage'] ?? 0,
            'disk' => $metrics['disk_usage'] ?? 0,
            'response_time' => $metrics['avg_response_time'] ?? 0,
            'error_rate' => $metrics['error_rate'] ?? 0,
            'requests_per_second' => $metrics['requests_per_second'] ?? 0,
            'active_users' => $metrics['active_users'] ?? 0,
        ];
    }

    /**
     * Store daily summary
     */
    protected function storeDailySummary(array $snapshot): void
    {
        $date = now()->toDateString();
        $dailyKey = "{$this->snapshotsKey}:{$date}";

        $dailyData = Cache::get($dailyKey, [
            'date' => $date,
            'snapshots' => [],
            'min' => [],
            'max' => [],
            'avg' => [],
        ]);

        $dailyData['snapshots'][] = $snapshot['summary'];

        // Calculate min, max, avg
        $summaries = $dailyData['snapshots'];
        foreach (['cpu', 'memory', 'disk', 'response_time', 'error_rate', 'requests_per_second'] as $metric) {
            $values = array_column($summaries, $metric);
            if (!empty($values)) {
                $dailyData['min'][$metric] = min($values);
                $dailyData['max'][$metric] = max($values);
                $dailyData['avg'][$metric] = array_sum($values) / count($values);
            }
        }

        Cache::put($dailyKey, $dailyData, 86400 * 90); // 90 days
    }

    /**
     * Get performance history
     */
    public function getHistory(
        int $hours = 24,
        ?string $metric = null,
        int $limit = 100
    ): array {
        $history = Cache::get($this->historyKey, []);
        $cutoff = now()->subHours($hours);

        $filtered = array_filter($history, function ($snapshot) use ($cutoff) {
            return Carbon::parse($snapshot['timestamp'])->gte($cutoff);
        });

        // Apply limit
        $filtered = array_slice($filtered, -$limit);

        // Extract specific metric if requested
        if ($metric) {
            $filtered = array_map(function ($snapshot) use ($metric) {
                return [
                    'timestamp' => $snapshot['timestamp'],
                    'value' => $snapshot['summary'][$metric] ?? null,
                ];
            }, $filtered);
        }

        return array_values($filtered);
    }

    /**
     * Get daily summaries for date range
     */
    public function getDailySummaries(string $startDate, string $endDate): array
    {
        $summaries = [];
        $start = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);

        while ($start->lte($end)) {
            $date = $start->toDateString();
            $dailyKey = "{$this->snapshotsKey}:{$date}";
            $dailyData = Cache::get($dailyKey);

            if ($dailyData) {
                $summaries[] = $dailyData;
            }

            $start->addDay();
        }

        return $summaries;
    }

    /**
     * Compare two time periods
     */
    public function comparePeriods(
        string $period1Start,
        string $period1End,
        string $period2Start,
        string $period2End
    ): array {
        $period1Stats = $this->getPeriodStats($period1Start, $period1End);
        $period2Stats = $this->getPeriodStats($period2Start, $period2End);

        $comparison = [];
        $metrics = ['cpu', 'memory', 'disk', 'response_time', 'error_rate', 'requests_per_second'];

        foreach ($metrics as $metric) {
            $p1Avg = $period1Stats['avg'][$metric] ?? 0;
            $p2Avg = $period2Stats['avg'][$metric] ?? 0;

            $diff = $p2Avg - $p1Avg;
            $percentChange = $p1Avg > 0 ? ($diff / $p1Avg) * 100 : 0;

            $comparison[$metric] = [
                'period1' => [
                    'avg' => round($p1Avg, 2),
                    'min' => $period1Stats['min'][$metric] ?? 0,
                    'max' => $period1Stats['max'][$metric] ?? 0,
                ],
                'period2' => [
                    'avg' => round($p2Avg, 2),
                    'min' => $period2Stats['min'][$metric] ?? 0,
                    'max' => $period2Stats['max'][$metric] ?? 0,
                ],
                'change' => [
                    'absolute' => round($diff, 2),
                    'percent' => round($percentChange, 2),
                    'direction' => $diff > 0 ? 'increased' : ($diff < 0 ? 'decreased' : 'unchanged'),
                ],
                'regression' => $this->isRegression($metric, $diff),
            ];
        }

        return [
            'period1' => [
                'start' => $period1Start,
                'end' => $period1End,
                'stats' => $period1Stats,
            ],
            'period2' => [
                'start' => $period2Start,
                'end' => $period2End,
                'stats' => $period2Stats,
            ],
            'comparison' => $comparison,
            'summary' => $this->generateComparisonSummary($comparison),
        ];
    }

    /**
     * Get period statistics
     */
    protected function getPeriodStats(string $startDate, string $endDate): array
    {
        $history = Cache::get($this->historyKey, []);
        $start = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);

        $filtered = array_filter($history, function ($snapshot) use ($start, $end) {
            $time = Carbon::parse($snapshot['timestamp']);
            return $time->gte($start) && $time->lte($end);
        });

        $stats = [
            'count' => count($filtered),
            'avg' => [],
            'min' => [],
            'max' => [],
        ];

        $metrics = ['cpu', 'memory', 'disk', 'response_time', 'error_rate', 'requests_per_second'];

        foreach ($metrics as $metric) {
            $values = array_column(array_column($filtered, 'summary'), $metric);
            $values = array_filter($values, fn($v) => $v !== null);

            if (!empty($values)) {
                $stats['avg'][$metric] = array_sum($values) / count($values);
                $stats['min'][$metric] = min($values);
                $stats['max'][$metric] = max($values);
            } else {
                $stats['avg'][$metric] = 0;
                $stats['min'][$metric] = 0;
                $stats['max'][$metric] = 0;
            }
        }

        return $stats;
    }

    /**
     * Check if change is a regression
     */
    protected function isRegression(string $metric, float $change): bool
    {
        $regressionThresholds = [
            'cpu' => 20,          // 20% increase is regression
            'memory' => 15,       // 15% increase
            'disk' => 10,         // 10% increase
            'response_time' => 25, // 25% increase
            'error_rate' => 50,   // 50% increase
            'requests_per_second' => -20, // 20% decrease
        ];

        $threshold = $regressionThresholds[$metric] ?? 20;

        // For most metrics, increase is bad; for RPS, decrease is bad
        if ($metric === 'requests_per_second') {
            return $change < $threshold;
        }

        return $change > $threshold;
    }

    /**
     * Generate comparison summary
     */
    protected function generateComparisonSummary(array $comparison): array
    {
        $regressions = [];
        $improvements = [];

        foreach ($comparison as $metric => $data) {
            if ($data['regression']) {
                $regressions[] = [
                    'metric' => $metric,
                    'change' => $data['change']['percent'],
                ];
            } elseif ($data['change']['percent'] < -5) {
                $improvements[] = [
                    'metric' => $metric,
                    'change' => $data['change']['percent'],
                ];
            }
        }

        return [
            'has_regressions' => count($regressions) > 0,
            'regression_count' => count($regressions),
            'improvement_count' => count($improvements),
            'regressions' => $regressions,
            'improvements' => $improvements,
        ];
    }

    /**
     * Get performance trend
     */
    public function getTrend(string $metric, int $days = 7): array
    {
        $history = Cache::get($this->historyKey, []);
        $cutoff = now()->subDays($days);

        $dailyData = [];
        foreach ($history as $snapshot) {
            $time = Carbon::parse($snapshot['timestamp']);
            if ($time->gte($cutoff)) {
                $date = $time->toDateString();
                if (!isset($dailyData[$date])) {
                    $dailyData[$date] = [];
                }
                $dailyData[$date][] = $snapshot['summary'][$metric] ?? 0;
            }
        }

        $trend = [];
        foreach ($dailyData as $date => $values) {
            $trend[] = [
                'date' => $date,
                'avg' => array_sum($values) / count($values),
                'min' => min($values),
                'max' => max($values),
                'count' => count($values),
            ];
        }

        usort($trend, fn($a, $b) => strcmp($a['date'], $b['date']));

        return $trend;
    }

    /**
     * Export comparison report
     */
    public function exportReport(
        string $period1Start,
        string $period1End,
        string $period2Start,
        string $period2End,
        string $format = 'json'
    ): array {
        $comparison = $this->comparePeriods(
            $period1Start,
            $period1End,
            $period2Start,
            $period2End
        );

        $report = [
            'generated_at' => now()->toISOString(),
            'format' => $format,
            'periods' => [
                'period1' => ['start' => $period1Start, 'end' => $period1End],
                'period2' => ['start' => $period2Start, 'end' => $period2End],
            ],
            'metrics' => $comparison['comparison'],
            'summary' => $comparison['summary'],
            'trends' => [],
        ];

        // Add trends for each metric
        foreach (['cpu', 'memory', 'disk', 'response_time'] as $metric) {
            $report['trends'][$metric] = $this->getTrend($metric, 30);
        }

        return $report;
    }

    /**
     * Clear history
     */
    public function clearHistory(?string $beforeDate = null): void
    {
        if ($beforeDate) {
            $history = Cache::get($this->historyKey, []);
            $cutoff = Carbon::parse($beforeDate);

            $history = array_filter($history, function ($snapshot) use ($cutoff) {
                return Carbon::parse($snapshot['timestamp'])->gt($cutoff);
            });

            Cache::put($this->historyKey, array_values($history), 86400 * 30);
        } else {
            Cache::forget($this->historyKey);
        }
    }
}
