<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = config('database.default');

        // Helper: only create index if it doesn't exist
        $createIndex = function (string $table, string $indexName, callable $definition) use ($driver) {
            try {
                if ($driver === 'sqlite') {
                    $exists = \DB::select("SELECT name FROM sqlite_master WHERE type='index' AND name=?", [$indexName]);
                    if (!empty($exists)) return;
                } else {
                    $exists = \DB::select("SHOW INDEX FROM `{$table}` WHERE Key_name=?", [$indexName]);
                    if (!empty($exists)) return;
                }
                Schema::table($table, $definition);
            } catch (\Exception $e) {
                // Index may already exist or table may not exist, skip silently
            }
        };

        // Bookings: Quick lookup by status and date
        $createIndex('bookings', 'idx_bookings_status_date', function (Blueprint $table) {
            $table->index(['status', 'date'], 'idx_bookings_status_date');
        });

        // Payments: Quick lookup by status
        $createIndex('payments', 'idx_payments_status', function (Blueprint $table) {
            $table->index('status', 'idx_payments_status');
        });

        // Reviews: Average rating calculation
        $createIndex('reviews', 'idx_reviews_studio_rating', function (Blueprint $table) {
            $table->index(['studio_id', 'rating'], 'idx_reviews_studio_rating');
        });

        // Full-text search (MySQL only)
        if ($driver !== 'sqlite') {
            $createIndex('studios', 'idx_studios_fulltext_search', function (Blueprint $table) {
                $table->fullText(['name', 'description', 'city'], 'idx_studios_fulltext_search');
            });
        }

        // Notifications: Quick lookup by user and read status
        $createIndex('notifications', 'idx_notifications_user_read', function (Blueprint $table) {
            $table->index(['user_id', 'is_read'], 'idx_notifications_user_read');
        });

        // Promos: Active promos lookup
        $createIndex('promos', 'idx_promos_active_dates', function (Blueprint $table) {
            $table->index(['is_active', 'start_date', 'end_date'], 'idx_promos_active_dates');
        });

        // Chat rooms
        $createIndex('chat_rooms', 'idx_chat_rooms_participants', function (Blueprint $table) {
            $table->index(['customer_id', 'owner_id', 'status'], 'idx_chat_rooms_participants');
        });

        // Dynamic pricing
        $createIndex('dynamic_pricing_rules', 'idx_pricing_rules_lookup', function (Blueprint $table) {
            $table->index(['studio_room_id', 'is_active', 'priority'], 'idx_pricing_rules_lookup');
        });

        // Referrals
        $createIndex('referrals', 'idx_referrals_active', function (Blueprint $table) {
            $table->index(['is_active', 'uses_count'], 'idx_referrals_active');
        });
    }

    public function down(): void
    {
        $indexes = [
            'bookings' => 'idx_bookings_status_date',
            'payments' => 'idx_payments_status',
            'reviews' => 'idx_reviews_studio_rating',
            'notifications' => 'idx_notifications_user_read',
            'promos' => 'idx_promos_active_dates',
            'chat_rooms' => 'idx_chat_rooms_participants',
            'dynamic_pricing_rules' => 'idx_pricing_rules_lookup',
            'referrals' => 'idx_referrals_active',
        ];

        foreach ($indexes as $table => $index) {
            try {
                Schema::table($table, function (Blueprint $table) use ($index) {
                    $table->dropIndex($index);
                });
            } catch (\Exception $e) {}
        }

        if (config('database.default') !== 'sqlite') {
            try {
                Schema::table('studios', function (Blueprint $table) {
                    $table->dropIndex('idx_studios_fulltext_search');
                });
            } catch (\Exception $e) {}
        }
    }
};
