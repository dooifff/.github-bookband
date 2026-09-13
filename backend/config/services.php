<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Google Sign-In
    |--------------------------------------------------------------------------
    |
    | Daftar OAuth Client ID yang diizinkan mengirim ID token ke endpoint
    | /api/v1/auth/google. Isi beberapa client ID dipisahkan koma karena
    | audience (klaim "aud") token berbeda untuk web, Android, dan iOS.
    |
    */

    'google' => [
        'client_ids' => env('GOOGLE_CLIENT_IDS', ''),
    ],

];
