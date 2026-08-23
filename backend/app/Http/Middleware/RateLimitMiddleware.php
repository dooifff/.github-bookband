<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

class RateLimitMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string $key = 'api', int $maxAttempts = 60, int $decayMinutes = 1): Response
    {
        $rateLimiterKey = $key . '|' . $request->ip();

        if (RateLimiter::tooManyAttempts($rateLimiterKey, $maxAttempts)) {
            $seconds = RateLimiter::availableIn($rateLimiterKey);

            return response()->json([
                'success' => false,
                'message' => 'Terlalu banyak percobaan. Silakan coba lagi dalam ' . $seconds . ' detik.',
                'retry_after' => $seconds,
            ], 429);
        }

        RateLimiter::hit($rateLimiterKey, $decayMinutes * 60);

        $response = $next($request);

        return $this->addHeaders($response, $maxAttempts, $decayMinutes);
    }

    /**
     * Add the rate limiting headers to the response.
     */
    protected function addHeaders(Response $response, int $maxAttempts, int $decayMinutes): Response
    {
        $response->headers->set('X-RateLimit-Limit', $maxAttempts);
        $response->headers->set('X-RateLimit-Remaining', $maxAttempts - 1);

        return $response;
    }
}
