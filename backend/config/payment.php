<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Default Payment Provider
    |--------------------------------------------------------------------------
    */
    'default_provider' => env('PAYMENT_DEFAULT_PROVIDER', 'midtrans'),

    /*
    |--------------------------------------------------------------------------
    | Midtrans Configuration
    |--------------------------------------------------------------------------
    */
    'midtrans' => [
        'client_key' => env('MIDTRANS_CLIENT_KEY'),
        'server_key' => env('MIDTRANS_SERVER_KEY'),
        'is_production' => env('MIDTRANS_IS_PRODUCTION', false),
    ],

    /*
    |--------------------------------------------------------------------------
    | Xendit Configuration
    |--------------------------------------------------------------------------
    */
    'xendit' => [
        'secret_key' => env('XENDIT_SECRET_KEY'),
        'public_key' => env('XENDIT_PUBLIC_KEY'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Payment Methods
    |--------------------------------------------------------------------------
    */
    'methods' => [
        'bank_transfer' => [
            'name' => 'Transfer Bank',
            'providers' => ['midtrans', 'xendit'],
        ],
        'credit_card' => [
            'name' => 'Kartu Kredit',
            'providers' => ['midtrans', 'xendit'],
        ],
        'debit_card' => [
            'name' => 'Kartu Debit',
            'providers' => ['midtrans', 'xendit'],
        ],
        'ewallet' => [
            'name' => 'E-Wallet',
            'providers' => ['midtrans', 'xendit'],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Payment Expiry (in hours)
    |--------------------------------------------------------------------------
    */
    'expiry_hours' => env('PAYMENT_EXPIRY_HOURS', 24),
];
