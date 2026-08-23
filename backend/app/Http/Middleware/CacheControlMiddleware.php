<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class CacheControlMiddleware
{
    /**
     * CDN-specific surrogate keys for targeted purging
     */
    protected array $surrogateKeys = [
        'studios' => 'studios listing-detail search',
        'promos' => 'promos active',
        'reviews' => 'reviews studio-reviews',
        'auth' => 'auth user-profile',
        'health' => 'health',
    ];

    /**
     * Handle an incoming request and add Cache-Control + CDN headers.
     */
    public function handle(Request $request, Closure $next, string $type = 'public', string|int $maxAge = 300): Response
    {
        $maxAge = (int) $maxAge;
        $response = $next($request);

        // Don't cache error responses or non-GET/HEAD
        if ($response->getStatusCode() >= 400 || !in_array($request->method(), ['GET', 'HEAD'])) {
            $this->addNoCacheHeaders($response);
            return $response;
        }

        // Build standard cache headers
        $headers = $this->getCacheHeaders($type, $maxAge);

        foreach ($headers as $key => $value) {
            $response->headers->set($key, $value);
        }

        // Add CDN-specific headers for production
        if (App::environment('production', 'staging')) {
            $this->addCdnHeaders($response, $request, $type, $maxAge);
        }

        // Add Surrogate-Control (for Varnish, Fastly, etc.)
        $this->addSurrogateHeaders($response, $request, $type, $maxAge);

        // Add ETag based on response content for validation
        $content = $response->getContent();
        if ($content && $request->method() === 'GET') {
            $etag = '"' . md5($content) . '"';
            $response->headers->set('ETag', $etag);

            // Check If-None-Match for 304 responses
            $ifNoneMatch = $request->header('If-None-Match');
            if ($ifNoneMatch === $etag) {
                $notModified = response('', 304);
                foreach ($headers as $key => $value) {
                    $notModified->headers->set($key, $value);
                }
                $notModified->headers->set('ETag', $etag);

                // Preserve CDN headers on 304
                if (App::environment('production', 'staging')) {
                    $this->addCdnHeaders($notModified, $request, $type, $maxAge);
                }
                $this->addSurrogateHeaders($notModified, $request, $type, $maxAge);

                return $notModified;
            }
        }

        return $response;
    }

    /**
     * Get cache headers based on type
     */
    protected function getCacheHeaders(string $type, int $maxAge): array
    {
        return match ($type) {
            'public' => [
                'Cache-Control' => "public, max-age={$maxAge}, s-maxage={$maxAge}",
                'Vary' => 'Accept, Accept-Language',
            ],
            'private' => [
                'Cache-Control' => "private, max-age={$maxAge}",
                'Vary' => 'Authorization, Accept',
            ],
            'no-cache' => [
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
                'Pragma' => 'no-cache',
                'Expires' => '0',
            ],
            default => [
                'Cache-Control' => "public, max-age={$maxAge}",
            ],
        };
    }

    /**
     * Add CDN-specific headers for production environments
     *
     * Supported CDNs:
     * - Cloudflare: CDN-Cache-Control, CF-Cache-Status
     * - Fastly: Surrogate-Control, Surrogate-Key
     * - CloudFront: X-Cache, X-Amz-Cf-Pop
     * - Generic: CDN-Cache-Control, Surrogate-Control
     */
    protected function addCdnHeaders(Response $response, Request $request, string $type, int $maxAge): void
    {
        // CDN-Cache-Control: instructs CDNs independently of browser caching
        if ($type === 'public') {
            $surrogateMaxAge = $maxAge * 2; // CDNs cache longer than browsers
            $response->headers->set('CDN-Cache-Control', "public, max-age={$surrogateMaxAge}, s-maxage={$surrogateMaxAge}");
        } elseif ($type === 'private') {
            $response->headers->set('CDN-Cache-Control', 'private, no-store');
        } else {
            $response->headers->set('CDN-Cache-Control', 'no-store');
        }

        // Surrogate-Control: for Varnish/Fastly surrogate caching
        if ($type === 'public') {
            $surrogateMaxAge = $maxAge * 2;
            $response->headers->set('Surrogate-Control', "public, max-age={$surrogateMaxAge}");
        } elseif ($type === 'no-cache') {
            $response->headers->set('Surrogate-Control', 'no-store');
        }
    }

    /**
     * Add Surrogate headers for cache key tracking and targeted purging
     */
    protected function addSurrogateHeaders(Response $response, Request $request, string $type, int $maxAge): void
    {
        if ($type !== 'public') {
            return;
        }

        // Determine surrogate key based on route
        $path = $request->path();
        $key = $this->getSurrogateKey($path);

        if ($key) {
            $response->headers->set('Surrogate-Key', $key);
        }

        // Add cache version header for CDN invalidation
        $response->headers->set('X-Cache-Version', config('app.version', '1.0.0'));
    }

    /**
     * Map route paths to surrogate keys for targeted purging
     */
    protected function getSurrogateKey(string $path): ?string
    {
        foreach ($this->surrogateKeys as $pattern => $key) {
            if (str_starts_with($path, "v1/{$pattern}") || str_contains($path, $pattern)) {
                return $key;
            }
        }

        return null;
    }

    /**
     * Add no-cache headers for error responses
     */
    protected function addNoCacheHeaders(Response $response): void
    {
        $response->headers->set('Cache-Control', 'no-cache, no-store, must-revalidate');
        $response->headers->set('Pragma', 'no-cache');
        $response->headers->set('Expires', '0');
    }
}
