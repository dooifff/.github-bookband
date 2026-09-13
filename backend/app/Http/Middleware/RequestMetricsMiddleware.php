<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class RequestMetricsMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);

        $response = $next($request);

        try {
            $endTime = microtime(true);
            $responseTimeMs = round(($endTime - $startTime) * 1000, 2);

            // Add performance header only
            $response->headers->set('X-Response-Time', $responseTimeMs . 'ms');
        } catch (\Exception $e) {
            // Never let metrics tracking break the request
        }

        return $response;
    }
}
