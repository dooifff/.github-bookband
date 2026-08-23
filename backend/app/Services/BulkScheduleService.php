<?php

namespace App\Services;

use App\Models\BlockedSchedule;
use App\Models\Studio;
use App\Models\StudioRoom;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Illuminate\Support\Facades\DB;

class BulkScheduleService
{
    /**
     * Block multiple dates for a room
     */
    public function blockDates(int $roomId, array $dates, ?string $reason = null): array
    {
        $room = StudioRoom::findOrFail($roomId);
        $blockedSchedules = [];

        DB::beginTransaction();

        try {
            foreach ($dates as $date) {
                // Check for existing bookings
                $hasBooking = $this->checkExistingBookings($roomId, $date);
                
                if ($hasBooking) {
                    throw new \Exception("Ruangan {$room->name} sudah memiliki booking pada tanggal {$date}");
                }

                // Check for existing blocked schedule
                $existingBlock = BlockedSchedule::where('studio_room_id', $roomId)
                    ->where('date', $date)
                    ->exists();

                if (!$existingBlock) {
                    $blocked = BlockedSchedule::create([
                        'studio_id' => $room->studio_id,
                        'studio_room_id' => $roomId,
                        'date' => $date,
                        'start_time' => '00:00:00',
                        'end_time' => '23:59:59',
                        'reason' => $reason ?? 'Bulk block',
                        'is_recurring' => false,
                    ]);
                    $blockedSchedules[] = $blocked;
                }
            }

            DB::commit();
            return $blockedSchedules;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Block date range for a room
     */
    public function blockDateRange(
        int $roomId,
        string $startDate,
        string $endDate,
        ?string $startTime = null,
        ?string $endTime = null,
        ?string $reason = null
    ): array {
        $room = StudioRoom::findOrFail($roomId);
        $period = CarbonPeriod::create($startDate, $endDate);
        $blockedSchedules = [];

        DB::beginTransaction();

        try {
            foreach ($period as $date) {
                $dateStr = $date->toDateString();

                // Check for existing bookings
                $hasBooking = $this->checkExistingBookings($roomId, $dateStr);
                
                if ($hasBooking) {
                    throw new \Exception("Ruangan {$room->name} sudah memiliki booking pada tanggal {$dateStr}");
                }

                // Check for existing blocked schedule
                $existingBlock = BlockedSchedule::where('studio_room_id', $roomId)
                    ->where('date', $dateStr)
                    ->exists();

                if (!$existingBlock) {
                    $blocked = BlockedSchedule::create([
                        'studio_id' => $room->studio_id,
                        'studio_room_id' => $roomId,
                        'date' => $dateStr,
                        'start_time' => $startTime ?? '00:00:00',
                        'end_time' => $endTime ?? '23:59:59',
                        'reason' => $reason ?? 'Bulk block',
                        'is_recurring' => false,
                    ]);
                    $blockedSchedules[] = $blocked;
                }
            }

            DB::commit();
            return $blockedSchedules;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Block recurring schedule (weekly)
     */
    public function blockRecurring(
        int $roomId,
        array $daysOfWeek,
        string $startDate,
        string $endDate,
        ?string $startTime = null,
        ?string $endTime = null,
        ?string $reason = null
    ): array {
        $room = StudioRoom::findOrFail($roomId);
        $period = CarbonPeriod::create($startDate, $endDate);
        $blockedSchedules = [];

        DB::beginTransaction();

        try {
            foreach ($period as $date) {
                // Check if this day of week is in the array
                $dayOfWeek = $date->dayOfWeek; // 0=Sunday, 6=Saturday
                
                if (!in_array($dayOfWeek, $daysOfWeek)) {
                    continue;
                }

                $dateStr = $date->toDateString();

                // Check for existing bookings
                $hasBooking = $this->checkExistingBookings($roomId, $dateStr);
                
                if ($hasBooking) {
                    continue; // Skip this date if there's a booking
                }

                // Check for existing blocked schedule
                $existingBlock = BlockedSchedule::where('studio_room_id', $roomId)
                    ->where('date', $dateStr)
                    ->exists();

                if (!$existingBlock) {
                    $blocked = BlockedSchedule::create([
                        'studio_id' => $room->studio_id,
                        'studio_room_id' => $roomId,
                        'date' => $dateStr,
                        'start_time' => $startTime ?? '00:00:00',
                        'end_time' => $endTime ?? '23:59:59',
                        'reason' => $reason ?? 'Recurring block',
                        'is_recurring' => true,
                        'recurrence_pattern' => json_encode([
                            'days_of_week' => $daysOfWeek,
                            'start_date' => $startDate,
                            'end_date' => $endDate,
                        ]),
                    ]);
                    $blockedSchedules[] = $blocked;
                }
            }

            DB::commit();
            return $blockedSchedules;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Block multiple rooms for same dates
     */
    public function blockMultipleRooms(
        array $roomIds,
        array $dates,
        ?string $reason = null
    ): array {
        $allBlocked = [];

        DB::beginTransaction();

        try {
            foreach ($roomIds as $roomId) {
                $blocked = $this->blockDates($roomId, $dates, $reason);
                $allBlocked = array_merge($allBlocked, $blocked);
            }

            DB::commit();
            return $allBlocked;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Remove blocked schedules in bulk
     */
    public function removeBulk(array $blockedIds): int
    {
        return BlockedSchedule::whereIn('id', $blockedIds)
            ->where('is_recurring', false)
            ->delete();
    }

    /**
     * Remove all blocked schedules for a room in date range
     */
    public function removeByDateRange(int $roomId, string $startDate, string $endDate): int
    {
        return BlockedSchedule::where('studio_room_id', $roomId)
            ->whereBetween('date', [$startDate, $endDate])
            ->delete();
    }

    /**
     * Check if room has existing bookings for a date
     */
    protected function checkExistingBookings(int $roomId, string $date): bool
    {
        return \App\Models\Booking::where('studio_room_id', $roomId)
            ->where('date', $date)
            ->whereNotIn('status', ['cancelled'])
            ->exists();
    }

    /**
     * Get blocked schedules summary
     */
    public function getBlockedSummary(int $roomId, string $startDate, string $endDate): array
    {
        $blocked = BlockedSchedule::where('studio_room_id', $roomId)
            ->whereBetween('date', [$startDate, $endDate])
            ->get();

        return [
            'total_blocked_days' => $blocked->count(),
            'dates' => $blocked->pluck('date'),
            'recurring_blocks' => $blocked->where('is_recurring', true)->count(),
            'one_time_blocks' => $blocked->where('is_recurring', false)->count(),
        ];
    }
}
