<?php

use App\Exceptions\Handler;
use Illuminate\Auth\Notifications\ResetPassword;
use App\Http\Middleware\RoleMiddleware;
use App\Http\Middleware\SecurityHeadersMiddleware;
use App\Http\Middleware\RequestMetricsMiddleware;
use App\Http\Middleware\CacheControlMiddleware;
use App\Http\Middleware\RateLimitMiddleware;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
$app = Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Token-based auth (no CSRF needed)
        // $middleware->statefulApi(); // disabled - using Bearer tokens
        
        // Global middleware
        $middleware->append(SecurityHeadersMiddleware::class);
        $middleware->append(RequestMetricsMiddleware::class);
        
        // Register custom middleware aliases
        $middleware->alias([
            'role' => RoleMiddleware::class,
            'throttle' => RateLimitMiddleware::class,
            'cache.public' => CacheControlMiddleware::class . ':public,300',
            'cache.private' => CacheControlMiddleware::class . ':private,60',
            'cache.no' => CacheControlMiddleware::class . ':no-cache,0',
        ]);
    })
    ->withSchedule(function ($schedule) {
        // Performance Reports - disabled until commands exist
        // $schedule->command('performance:send-reports --type=weekly')
        //     ->weekly()->mondays()->at('09:00')->withoutOverlapping();
        // $schedule->command('performance:send-reports --type=monthly')
        //     ->monthlyOn(1, '09:00')->withoutOverlapping();

        // Studio subscription enforcement (warning emails + auto delete)
        $schedule->command('studio-subscription:check')
            ->dailyAt(config('subscription.schedule_time', '06:00'))
            ->withoutOverlapping();
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Custom exception handling can be configured here
    })->create();

/*
|--------------------------------------------------------------------------
| Reset password link
|--------------------------------------------------------------------------
|
| Tautan di email reset diarahkan ke halaman frontend (web + deep link
| mobile) bukan ke endpoint API, karena token diisi di form:  
| {FRONTEND_URL}/reset-password?token=..&email=..
|
*/
ResetPassword::createUrlUsing(function ($notifiable, string $token) {
    $frontend = env('FRONTEND_URL') ?: env('APP_URL') ?: 'http://localhost:5173';

    return rtrim((string) $frontend, '/').'/reset-password?token='.$token
        .'&email='.urlencode($notifiable->getEmailForPasswordReset());
});

return $app;
