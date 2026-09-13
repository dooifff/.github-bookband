<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Studio;
use App\Notifications\StudioSubscriptionNotification;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class StudioSubscriptionService
{
    public const STATUS_NONE = 'none';
    public const STATUS_ACTIVE = 'active';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_REMOVED = 'removed';

    /**
     * Booking statuses that block automatic studio deletion.
     */
    protected array $blockingBookingStatuses = [
        'pending', 'awaiting_payment', 'paid', 'confirmed', 'ongoing',
    ];

    public function isEnabled(): bool
    {
        return (bool) config('subscription.enabled', true);
    }

    /**
     * Mark studios whose subscription has just ended as "expired".
     */
    public function markExpired(): int
    {
        $count = 0;

        Studio::where('subscription_status', self::STATUS_ACTIVE)
            ->where('subscription_expires_at', '<=', now())
            ->chunkById(100, function ($studios) use (&$count) {
                foreach ($studios as $studio) {
                    $studio->update([
                        'subscription_status' => self::STATUS_EXPIRED,
                        'subscription_warning_level' => 0,
                        'subscription_last_warning_at' => null,
                    ]);
                    $count++;
                }
            });

        return $count;
    }

    /**
     * Run the 3-stage escalation for expired studios:
     *   1. first warning email
     *   2. second warning email (same message + extra wording)
     *   3. automatic deletion (if no active bookings block it)
     */
    public function escalate(): array
    {
        $stats = [
            'first_warnings_sent' => 0,
            'second_warnings_sent' => 0,
            'deleted' => 0,
            'deletion_blocked_by_bookings' => 0,
        ];

        if (!$this->isEnabled()) {
            return $stats;
        }

        $warn1Days = (int) config('subscription.warn1_days', 1);
        $warn2Days = (int) config('subscription.warn2_days', 3);
        $deleteDays = (int) config('subscription.delete_days', 7);

        Studio::where('subscription_status', self::STATUS_EXPIRED)
            ->with('owner')
            ->orderBy('subscription_expires_at')
            ->chunkById(100, function ($studios) use (&$stats, $warn1Days, $warn2Days, $deleteDays) {
                foreach ($studios as $studio) {
                    $daysOverdue = $this->daysOverdue($studio->subscription_expires_at);

                    // Stage 1: first warning
                    if ($studio->subscription_warning_level < 1 && $daysOverdue >= $warn1Days) {
                        $this->sendWarning($studio, 'first_warning');
                        $studio->update([
                            'subscription_warning_level' => 1,
                            'subscription_last_warning_at' => now(),
                        ]);
                        $stats['first_warnings_sent']++;
                        continue;
                    }

                    // Stage 2: second warning
                    if ($studio->subscription_warning_level < 2 && $daysOverdue >= $warn2Days) {
                        $this->sendWarning($studio, 'second_warning');
                        $studio->update([
                            'subscription_warning_level' => 2,
                            'subscription_last_warning_at' => now(),
                        ]);
                        $stats['second_warnings_sent']++;
                        continue;
                    }

                    // Stage 3: automatic deletion
                    if ($studio->subscription_warning_level >= 2 && $daysOverdue >= $deleteDays) {
                        if ($this->hasBlockingBookings($studio)) {
                            // Postpone deletion, retry on the next cron run
                            $stats['deletion_blocked_by_bookings']++;
                            continue;
                        }

                        $this->deleteStudio($studio);
                        $stats['deleted']++;
                    }
                }
            });

        return $stats;
    }

    /**
     * Run a full check: mark newly expired studios, then escalate.
     */
    public function run(): array
    {
        $newlyExpired = $this->markExpired();
        $stats = $this->escalate();
        $stats['newly_expired'] = $newlyExpired;

        return $stats;
    }

    /**
     * Calendar days since subscription_expires_at (>= 0 when overdue).
     */
    protected function daysOverdue(?Carbon $expiresAt): int
    {
        if (!$expiresAt) {
            return 0;
        }

        $days = (int) $expiresAt->startOfDay()->diffInDays(now()->startOfDay(), false);

        return max(0, $days);
    }

    protected function hasBlockingBookings(Studio $studio): bool
    {
        return Booking::where('studio_id', $studio->id)
            ->whereIn('status', $this->blockingBookingStatuses)
            ->exists();
    }

    protected function sendWarning(Studio $studio, string $stage): void
    {
        if (!$studio->owner) {
            return;
        }

        $studio->owner->notify(new StudioSubscriptionNotification($studio, $stage));
    }

    protected function deleteStudio(Studio $studio): void
    {
        // Final notification before deletion (owner account still exists)
        $this->sendWarning($studio, 'deleted');

        $studio->update([
            'subscription_status' => self::STATUS_REMOVED,
            'subscription_warning_level' => 3,
            'subscription_last_warning_at' => now(),
            'is_active' => false,
        ]);

        $studio->delete(); // soft delete, data still recoverable by admin

        Cache::forget('studios_listing');
    }
}
