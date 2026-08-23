<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\File;

class CacheInvalidationController extends Controller
{
    /**
     * Flush all application caches
     */
    public function flushAll(): JsonResponse
    {
        $cachesCleared = 0;

        // Clear Laravel cache
        Cache::flush();
        $cachesCleared++;

        // Clear compiled views
        $viewPath = storage_path('views');
        if (File::isDirectory($viewPath)) {
            File::cleanDirectory($viewPath);
            $cachesCleared++;
        }

        // Clear route cache files
        $routeCache = base_path('bootstrap/cache/routes-v7.php');
        if (File::exists($routeCache)) {
            File::delete($routeCache);
            $cachesCleared++;
        }

        return response()->json([
            'success' => true,
            'message' => 'Semua cache berhasil dibersihkan',
            'data' => [
                'caches_cleared' => $cachesCleared,
                'timestamp' => now()->toISOString(),
            ],
        ]);
    }

    /**
     * Flush studio-related caches
     */
    public function flushStudios(): JsonResponse
    {
        // Clear studio listing cache (ETag will regenerate)
        Cache::forget('studios_listing');
        Cache::forget('studios_active');

        // Clear any cached studio data
        Cache::forget('active_promos');

        return response()->json([
            'success' => true,
            'message' => 'Studio cache berhasil dibersihkan',
            'data' => [
                'timestamp' => now()->toISOString(),
            ],
        ]);
    }

    /**
     * Flush promo-related caches
     */
    public function flushPromos(): JsonResponse
    {
        Cache::forget('active_promos');

        return response()->json([
            'success' => true,
            'message' => 'Promo cache berhasil dibersihkan',
            'data' => [
                'timestamp' => now()->toISOString(),
            ],
        ]);
    }

    /**
     * Flush performance metrics cache
     */
    public function flushMetrics(): JsonResponse
    {
        // Clear performance metrics from cache
        $cleared = 0;
        for ($i = 0; $i < 60; $i++) {
            $key = 'metrics:requests:' . now()->subMinutes($i)->format('Y-m-d-H-i');
            if (Cache::forget($key)) $cleared++;
        }

        // Clear slow request counts
        for ($i = 0; $i < 60; $i++) {
            $key = 'metrics:slow_requests:' . now()->subMinutes($i)->format('Y-m-d-H-i');
            if (Cache::forget($key)) $cleared++;
        }

        // Clear realtime performance cache
        Cache::forget('performance:realtime');
        Cache::forget('performance:alerts:history');

        return response()->json([
            'success' => true,
            'message' => 'Metrics cache berhasil dibersihkan',
            'data' => [
                'metrics_cleared' => $cleared,
                'timestamp' => now()->toISOString(),
            ],
        ]);
    }

    /**
     * Get cache status overview
     */
    public function status(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                'driver' => config('cache.default'),
                'default_ttl' => config('cache.stores.file.ttl', 3600),
                'performance_log' => file_exists(storage_path('logs/performance.log'))
                    ? [
                        'size_kb' => round(filesize(storage_path('logs/performance.log')) / 1024, 1),
                        'last_modified' => date('c', filemtime(storage_path('logs/performance.log'))),
                    ]
                    : null,
                'cache_file' => config('cache.stores.file.path') ?? storage_path('framework/cache/data'),
            ],
        ]);
    }
}
