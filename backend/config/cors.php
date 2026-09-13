<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        env('FRONTEND_URL', 'http://localhost:5173'),
        env('ADMIN_URL', 'http://localhost:5174'),
        env('APP_URL', 'http://localhost:8000'),
    ],

    /*
     * Flutter web (`flutter run -d chrome`) disajikan dari port acak, mis.
     * http://localhost:54321, sehingga daftar origin di atas tidak pernah
     * cocok dan browser memblokir request login. Pola berikut mengizinkan
     * origin pengembangan lokal pada port berapa pun.
     */
    'allowed_origins_patterns' => env('APP_ENV') === 'production'
        ? []
        : [
            '#^https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$#',
            '#^https?://10\.0\.2\.2(:\d+)?$#',
        ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
