<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Scheduler Configuration
    |--------------------------------------------------------------------------
    |
    | Configure scheduled tasks for the application.
    |
    */

    /*
    |--------------------------------------------------------------------------
    | Performance Report Schedule
    |--------------------------------------------------------------------------
    |
    | Configure automatic performance report schedules.
    |
    */

    'performance_reports' => [

        /*
        |--------------------------------------------------------------------------
        | Daily Report
        |--------------------------------------------------------------------------
        */
        'daily' => [
            'enabled' => env('SCHEDULE_DAILY_REPORT', false),
            'time' => env('SCHEDULE_DAILY_TIME', '08:00'),
            'recipients' => array_filter([
                env('DAILY_REPORT_EMAIL_1'),
                env('DAILY_REPORT_EMAIL_2'),
            ]),
        ],

        /*
        |--------------------------------------------------------------------------
        | Weekly Report
        |--------------------------------------------------------------------------
        */
        'weekly' => [
            'enabled' => env('SCHEDULE_WEEKLY_REPORT', true),
            'day' => env('SCHEDULE_WEEKLY_DAY', 'monday'),
            'time' => env('SCHEDULE_WEEKLY_TIME', '09:00'),
            'recipients' => array_filter([
                env('WEEKLY_REPORT_EMAIL_1'),
                env('WEEKLY_REPORT_EMAIL_2'),
            ]),
        ],

        /*
        |--------------------------------------------------------------------------
        | Monthly Report
        |--------------------------------------------------------------------------
        */
        'monthly' => [
            'enabled' => env('SCHEDULE_MONTHLY_REPORT', true),
            'day' => env('SCHEDULE_MONTHLY_DAY', 1),
            'time' => env('SCHEDULE_MONTHLY_TIME', '09:00'),
            'recipients' => array_filter([
                env('MONTHLY_REPORT_EMAIL_1'),
                env('MONTHLY_REPORT_EMAIL_2'),
            ]),
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Cleanup Schedule
    |--------------------------------------------------------------------------
    |
    | Configure automatic cleanup tasks.
    |
    */

    'cleanup' => [

        /*
        |--------------------------------------------------------------------------
        | Old Reports Cleanup
        |--------------------------------------------------------------------------
        */
        'old_reports' => [
            'enabled' => true,
            'retention_days' => env('REPORT_RETENTION_DAYS', 90),
            'schedule' => 'weekly',
            'day' => 'sunday',
            'time' => '02:00',
        ],

        /*
        |--------------------------------------------------------------------------
        | Alert History Cleanup
        |--------------------------------------------------------------------------
        */
        'alert_history' => [
            'enabled' => true,
            'retention_days' => env('ALERT_RETENTION_DAYS', 30),
            'schedule' => 'daily',
            'time' => '03:00',
        ],

        /*
        |--------------------------------------------------------------------------
        | Cache Cleanup
        |--------------------------------------------------------------------------
        */
        'cache' => [
            'enabled' => true,
            'schedule' => 'daily',
            'time' => '04:00',
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Monitoring Schedule
    |--------------------------------------------------------------------------
    |
    | Configure performance monitoring checks.
    |
    */

    'monitoring' => [

        /*
        |--------------------------------------------------------------------------
        | Performance Check Interval
        |--------------------------------------------------------------------------
        */
        'check_interval' => env('MONITORING_CHECK_INTERVAL', 60), // seconds

        /*
        |--------------------------------------------------------------------------
        | Snapshot Storage
        |--------------------------------------------------------------------------
        */
        'snapshot' => [
            'enabled' => true,
            'interval' => env('SNAPSHOT_INTERVAL', 300), // 5 minutes
            'retention_days' => env('SNAPSHOT_RETENTION', 30),
        ],

    ],

];
