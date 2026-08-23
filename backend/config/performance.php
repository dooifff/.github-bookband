<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Slow Request Threshold (ms)
    |--------------------------------------------------------------------------
    | Requests slower than this are logged as slow.
    */
    'slow_request_threshold_ms' => env('PERF_SLOW_REQUEST_MS', 500),

    /*
    |--------------------------------------------------------------------------
    | Slow Query Threshold (ms)
    |--------------------------------------------------------------------------
    | Individual queries slower than this are logged.
    */
    'slow_query_threshold_ms' => env('PERF_SLOW_QUERY_MS', 100),

    /*
    |--------------------------------------------------------------------------
    | Response Time Thresholds (ms)
    |--------------------------------------------------------------------------
    | Used by alerts and dashboard color coding.
    */
    'thresholds' => [
        'response_time' => [
            'good' => 100,
            'warning' => 300,
            'critical' => 1000,
        ],
        'query_time' => [
            'good' => 50,
            'warning' => 200,
            'critical' => 500,
        ],
        'query_count' => [
            'good' => 10,
            'warning' => 30,
            'critical' => 50,
        ],
        'memory_mb' => [
            'good' => 8,
            'warning' => 16,
            'critical' => 32,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Webhooks for alerts
    |--------------------------------------------------------------------------
    */
    'webhooks' => env('PERF_WEBHOOKS', []),
    'alert_email' => env('PERF_ALERT_EMAIL', 'admin@studiobook.com'),
];
