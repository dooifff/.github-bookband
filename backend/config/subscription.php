<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Studio Subscription Enforcement
    |--------------------------------------------------------------------------
    |
    | Mengatur cron penagihan/peringatan untuk studio yang masa
    | berlangganannya berakhir tanpa perpanjangan:
    |
    |   - warn1_days   : H+berapa setelah jatuh tempo dikirim peringatan email ke-1
    |   - warn2_days   : H+berapa setelah jatuh tempo dikirim peringatan email ke-2
    |   - delete_days  : H+berapa setelah jatuh tempo studio dihapus otomatis
    |
    | Semua dihitung sejak subscription_expires_at (masa aktif berakhir).
    */

    'enabled' => env('SUBSCRIPTION_ENFORCEMENT_ENABLED', true),

    'warn1_days' => (int) env('SUBSCRIPTION_WARN1_DAYS', 1),

    'warn2_days' => (int) env('SUBSCRIPTION_WARN2_DAYS', 3),

    'delete_days' => (int) env('SUBSCRIPTION_DELETE_DAYS', 7),

    /*
    | Lama perpanjangan default (bulan) saat owner memperpanjang langganan.
    */
    'renewal_months' => (int) env('SUBSCRIPTION_RENEWAL_MONTHS', 1),

    /*
    | Jam cron dijalankan setiap hari (timezone server, lihat APP_TIMEZONE).
    */
    'schedule_time' => env('SUBSCRIPTION_CHECK_TIME', '06:00'),

];
