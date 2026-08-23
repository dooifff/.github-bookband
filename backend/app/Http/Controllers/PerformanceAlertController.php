<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\PerformanceAlertService;

class PerformanceAlertController extends Controller
{
    protected PerformanceAlertService $alertService;

    public function __construct(PerformanceAlertService $alertService)
    {
        $this->alertService = $alertService;
    }

    /**
     * Get current active alerts
     */
    public function index(Request $request)
    {
        $severity = $request->get('severity');
        $page = $request->get('page', 1);
        $perPage = $request->get('per_page', 20);

        $result = $this->alertService->getHistory($page, $perPage, $severity);

        return response()->json([
            'success' => true,
            'data' => $result['data'],
            'meta' => $result['meta'],
        ]);
    }

    /**
     * Get alert statistics
     */
    public function stats()
    {
        $stats = $this->alertService->getStatistics();

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    /**
     * Get alert thresholds
     */
    public function thresholds()
    {
        $thresholds = $this->alertService->getThresholds();

        return response()->json([
            'success' => true,
            'data' => $thresholds,
        ]);
    }

    /**
     * Update alert thresholds
     */
    public function updateThresholds(Request $request)
    {
        $request->validate([
            'thresholds' => 'required|array',
            'thresholds.*.warning' => 'required|numeric|min:0',
            'thresholds.*.critical' => 'required|numeric|min:0',
        ]);

        $this->alertService->updateThresholds($request->input('thresholds'));

        return response()->json([
            'success' => true,
            'message' => 'Thresholds updated successfully',
            'data' => $this->alertService->getThresholds(),
        ]);
    }

    /**
     * Check metrics and generate alerts
     */
    public function check(Request $request)
    {
        $request->validate([
            'metrics' => 'required|array',
        ]);

        $alerts = $this->alertService->checkAndAlert($request->input('metrics'));

        return response()->json([
            'success' => true,
            'data' => [
                'alerts' => $alerts,
                'count' => count($alerts),
                'has_critical' => collect($alerts)->contains('severity', 'critical'),
                'has_warning' => collect($alerts)->contains('severity', 'warning'),
            ],
        ]);
    }

    /**
     * Get active alerts only
     */
    public function active()
    {
        $alerts = $this->alertService->getCurrentAlerts();
        $activeAlerts = array_filter($alerts, fn($a) => $a['status'] === 'active');

        return response()->json([
            'success' => true,
            'data' => array_values($activeAlerts),
            'count' => count($activeAlerts),
        ]);
    }

    /**
     * Clear all alert history
     */
    public function clear()
    {
        $this->alertService->clearHistory();

        return response()->json([
            'success' => true,
            'message' => 'Alert history cleared',
        ]);
    }

    /**
     * Get real-time alert stream (SSE-ready)
     */
    public function realtime()
    {
        $alerts = $this->alertService->getCurrentAlerts();
        $stats = $this->alertService->getStatistics();

        return response()->json([
            'success' => true,
            'data' => [
                'alerts' => $alerts,
                'stats' => $stats,
                'timestamp' => now()->toISOString(),
            ],
        ]);
    }
}
