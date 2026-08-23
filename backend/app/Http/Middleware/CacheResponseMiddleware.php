<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class CacheResponseMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, int $minutes = 60): Response
    {
        if ($request->method() !== 'GET') {
            return $next($request);
        }

        $cacheKey = $this->getCacheKey($request);

        $response = Cache::remember($cacheKey, $minutes * 60, function () use ($request, $next) {
            return $next($request);
        });

        $response->headers->set('X-Cache', 'HIT');
        $response->headers->set('Cache-Control', "public, max-age=" . ($minutes * 60));

        return $response;
    }

    /**
     * Generate cache key based on request
     */
    protected function getCacheKey(Request $request): string
    {
        return 'api:' . $request->url() . ':' . md5($request->getQueryString() ?? '');
    }

    /**
     * Clear cache for specific pattern
     */
    public static function clearCache(string $pattern = 'api:*'): void
    {
        Cache::tags(['api'])->flush();
    }
}
