<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Artisan;

class QueryPerformanceCheck extends Command
{
    protected $signature = 'performance:query-check 
                            {--iterations=100 : Number of iterations per query}';

    protected $description = 'Check query performance for critical database queries';

    public function handle()
    {
        $iterations = $this->option('iterations');

        $this->info('');
        $this->info('╔══════════════════════════════════════════════════════════╗');
        $this->info('║        StudioBook Query Performance Check               ║');
        $this->info('╚══════════════════════════════════════════════════════════╝');
        $this->info('');
        $this->info("Iterations: {$iterations}");
        $this->info('');

        $results = [];

        // Test 1: Studios listing with rooms count
        $results[] = $this->testQuery(
            'Studios listing with rooms count',
            'SELECT s.*, COUNT(sr.id) as rooms_count 
             FROM studios s 
             LEFT JOIN studio_rooms sr ON sr.studio_id = s.id 
             WHERE s.is_active = 1 
             GROUP BY s.id',
            $iterations
        );

        // Test 2: Studio detail with reviews
        $results[] = $this->testQuery(
            'Studio detail with avg rating',
            'SELECT s.*, AVG(r.rating) as avg_rating, COUNT(r.id) as reviews_count
             FROM studios s
             LEFT JOIN reviews r ON r.studio_id = s.id
             WHERE s.id = 1
             GROUP BY s.id',
            $iterations
        );

        // Test 3: Available rooms for date
        $results[] = $this->testQuery(
            'Available rooms for specific date',
            'SELECT sr.*, s.name as studio_name
             FROM studio_rooms sr
             JOIN studios s ON s.id = sr.studio_id
             LEFT JOIN blocked_schedules bs ON bs.room_id = sr.id AND bs.date = "2025-03-15"
             WHERE sr.is_active = 1 AND bs.id IS NULL',
            $iterations
        );

        // Test 4: Bookings by user with studio info
        $results[] = $this->testQuery(
            'Bookings by user with studio info',
            'SELECT b.*, s.name as studio_name, sr.name as room_name
             FROM bookings b
             JOIN studios s ON s.id = b.studio_id
             JOIN studio_rooms sr ON sr.id = b.room_id
             WHERE b.user_id = 1
             ORDER BY b.date DESC, b.start_time DESC',
            $iterations
        );

        // Test 5: Favorites with studio details
        $results[] = $this->testQuery(
            'Favorites with studio details',
            'SELECT f.*, s.name, s.slug, s.city, s.price_from,
                    AVG(r.rating) as avg_rating
             FROM favorites f
             JOIN studios s ON s.id = f.studio_id
             LEFT JOIN reviews r ON r.studio_id = s.id
             WHERE f.user_id = 1
             GROUP BY f.id',
            $iterations
        );

        // Test 6: Active promos
        $results[] = $this->testQuery(
            'Active promos',
            'SELECT * FROM promos 
             WHERE is_active = 1 
             AND start_date <= CURDATE() 
             AND end_date >= CURDATE()',
            $iterations
        );

        // Test 7: Chat messages with pagination
        $results[] = $this->testQuery(
            'Chat messages with sender info',
            'SELECT cm.*, u.name as sender_name
             FROM chat_messages cm
             JOIN users u ON u.id = cm.sender_id
             WHERE cm.chat_room_id = 1
             ORDER BY cm.created_at DESC
             LIMIT 50',
            $iterations
        );

        // Test 9: Notification unread count
        $results[] = $this->testQuery(
            'Notification unread count',
            'SELECT COUNT(*) as unread_count 
             FROM notifications 
             WHERE user_id = 1 AND is_read = 0',
            $iterations
        );

        // Test 10: Admin dashboard stats
        $results[] = $this->testQuery(
            'Admin dashboard - total users',
            'SELECT COUNT(*) as total FROM users WHERE role = "customer"',
            $iterations
        );

        // Test 11: Search studios (LIKE query)
        $results[] = $this->testQuery(
            'Studio search with LIKE',
            'SELECT * FROM studios 
             WHERE is_active = 1 
             AND (name LIKE "%music%" OR description LIKE "%music%" OR city LIKE "%music%")
             LIMIT 20',
            $iterations
        );

        // Test 12: Owner revenue aggregation
        $results[] = $this->testQuery(
            'Owner revenue aggregation',
            'SELECT SUM(p.amount) as total_revenue, COUNT(DISTINCT b.id) as booking_count
             FROM payments p
             JOIN bookings b ON b.id = p.booking_id
             JOIN studios s ON s.id = b.studio_id
             WHERE s.owner_id = 1 AND p.status = "paid"',
            $iterations
        );

        // Summary
        $this->info('');
        $this->info('╔══════════════════════════════════════════════════════════╗');
        $this->info('║                    Summary                              ║');
        $this->info('╠══════════════════════════════════════════════════════════╣');

        $totalTime = 0;
        $goodCount = 0;
        $warnCount = 0;
        $poorCount = 0;

        foreach ($results as $result) {
            $avgTime = $result['avg_ms'];
            $totalTime += $avgTime;

            if ($avgTime < 10) {
                $goodCount++;
            } elseif ($avgTime < 50) {
                $warnCount++;
            } else {
                $poorCount++;
            }
        }

        $overallAvg = $totalTime / count($results);

        $this->info("║  Total Queries Tested:  " . count($results) . str_repeat(' ', 33 - strlen((string)count($results))) . "║");
        $this->info("║  Overall Avg Time:      " . round($overallAvg, 2) . "ms" . str_repeat(' ', 33 - strlen(round($overallAvg, 2) . 'ms')) . "║");
        $this->info("║  Good (<10ms):          {$goodCount}" . str_repeat(' ', 36 - strlen((string)$goodCount)) . "║");
        $this->info("║  Warning (10-50ms):     {$warnCount}" . str_repeat(' ', 36 - strlen((string)$warnCount)) . "║");
        $this->info("║  Poor (>50ms):          {$poorCount}" . str_repeat(' ', 36 - strlen((string)$poorCount)) . "║");
        $this->info('╚══════════════════════════════════════════════════════════╝');
        $this->info('');

        if ($poorCount > 0) {
            $this->warn('⚠️  Some queries are slow. Consider adding indexes or optimizing.');
        } else {
            $this->info('✅ All queries are performing well!');
        }

        $this->info('');

        return 0;
    }

    protected function testQuery(string $name, string $sql, int $iterations): array
    {
        $times = [];

        for ($i = 0; $i < $iterations; $i++) {
            $start = microtime(true);
            DB::select($sql);
            $end = microtime(true);
            $times[] = ($end - $start) * 1000; // Convert to ms
        }

        $avgTime = array_sum($times) / count($times);
        $minTime = min($times);
        $maxTime = max($times);

        // Determine status
        if ($avgTime < 10) {
            $status = '✅ GOOD';
            $color = 'info';
        } elseif ($avgTime < 50) {
            $status = '⚠️  WARN';
            $color = 'comment';
        } else {
            $status = '❌ POOR';
            $color = 'error';
        }

        $this->line("  {$status} {$name}", $color);
        $this->line("       Avg: " . round($avgTime, 2) . "ms | Min: " . round($minTime, 2) . "ms | Max: " . round($maxTime, 2) . "ms");

        return [
            'name' => $name,
            'avg_ms' => $avgTime,
            'min_ms' => $minTime,
            'max_ms' => $maxTime,
            'status' => $avgTime < 10 ? 'good' : ($avgTime < 50 ? 'warning' : 'poor'),
        ];
    }
}
