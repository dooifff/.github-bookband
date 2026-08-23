<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class CacheService
{
    /**
     * Cache duration in minutes
     */
    const SHORT_CACHE = 5;
    const MEDIUM_CACHE = 30;
    const LONG_CACHE = 60;
    const DAY_CACHE = 1440;

    /**
     * Get cached data or compute and cache it
     */
    public static function remember(string $key, int $minutes, callable $callback)
    {
        return Cache::remember($key, $minutes, $callback);
    }

    /**
     * Cache studio data
     */
    public static function cacheStudio($studio, callable $callback)
    {
        $key = "studio:{$studio->id}";
        return self::remember($key, self::MEDIUM_CACHE, $callback);
    }

    /**
     * Cache studio rooms
     */
    public static function cacheStudioRooms($studioId, callable $callback)
    {
        $key = "studio:{$studioId}:rooms";
        return self::remember($key, self::MEDIUM_CACHE, $callback);
    }

    /**
     * Cache availability data
     */
    public static function cacheAvailability($studioId, $date, callable $callback)
    {
        $key = "availability:{$studioId}:{$date}";
        return self::remember($key, self::SHORT_CACHE, $callback);
    }

    /**
     * Cache reviews
     */
    public static function cacheReviews($reviewableType, $reviewableId, callable $callback)
    {
        $key = "reviews:{$reviewableType}:{$reviewableId}";
        return self::remember($key, self::MEDIUM_CACHE, $callback);
    }

    /**
     * Cache statistics
     */
    public static function cacheStats(string $key, callable $callback)
    {
        return self::remember("stats:{$key}", self::LONG_CACHE, $callback);
    }

    /**
     * Clear studio cache
     */
    public static function clearStudioCache($studioId): void
    {
        Cache::forget("studio:{$studioId}");
        Cache::forget("studio:{$studioId}:rooms");
        Cache::forget("studio:{$studioId}:equipment");
        Cache::forget("studio:{$studioId}:opening-hours");
    }

    /**
     * Clear availability cache
     */
    public static function clearAvailabilityCache($studioId): void
    {
        $keys = Cache::get("availability:{$studioId}:*", []);
        foreach ($keys as $key) {
            Cache::forget($key);
        }
    }

    /**
     * Clear all cache
     */
    public static function clearAll(): void
    {
        Cache::flush();
    }

    /**
     * Get cache statistics
     */
    public static function getStats(): array
    {
        return [
            'hits' => Cache::getStore()->hits() ?? 0,
            'misses' => Cache::getStore()->misses() ?? 0,
            'keys' => Cache::getStore()->size() ?? 0,
        ];
    }

    /**
     * Warm up cache for popular studios
     */
    public static function warmUpStudioCache(): void
    {
        $studios = DB::table('studios')
            ->where('is_active', true)
            ->where('total_reviews', '>', 10)
            ->orderByDesc('total_reviews')
            ->limit(50)
            ->get();

        foreach ($studios as $studio) {
            self::cacheStudio($studio, function () use ($studio) {
                return $studio;
            });
        }
    }
}
