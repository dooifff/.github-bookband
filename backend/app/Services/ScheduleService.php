<?php

namespace App\Services;

use App\Models\BlockedSchedule;
use App\Models\Booking;
use App\Models\OpeningHour;
use App\Models\Studio;
use App\Models\StudioRoom;
use Carbon\Carbon;
use Carbon\CarbonPeriod;

class ScheduleService
{
    /**
     * Check if a room is available for given date and time range
     */
    public function isRoomAvailable(
        int $roomId,
        string $date,
        string $startTime,
        string $endTime,
        ?int $excludeBookingId = null
    ): bool {
        $room = StudioRoom::findOrFail($roomId);
        $studio = $room->studio;

        // 1. Check if room is active
        if (!$room->is_active) {
            return false;
        }

        // 2. Check if studio is active
        if (!$studio->is_active) {
            return false;
        }

        // 3. Check opening hours
        if (!$this->isStudioOpen($studio->id, $date, $startTime, $endTime)) {
            return false;
        }

        // 4. Check blocked schedules
        if ($this->isTimeBlocked($studio->id, $roomId, $date, $startTime, $endTime)) {
            return false;
        }

        // 5. Check overlapping bookings
        if ($this->hasOverlappingBooking($roomId, $date, $startTime, $endTime, $excludeBookingId)) {
            return false;
        }

        return true;
    }

    /**
     * Check if studio is open during the given time
     */
    public function isStudioOpen(int $studioId, string $date, string $startTime, string $endTime): bool
    {
        $dayOfWeek = Carbon::parse($date)->dayOfWeek; // 0=Sunday, 6=Saturday

        $openingHour = OpeningHour::where('studio_id', $studioId)
            ->where('day_of_week', $dayOfWeek)
            ->first();

        if (!$openingHour || $openingHour->is_closed) {
            return false;
        }

        // Check if booking time is within opening hours
        return $startTime >= $openingHour->open_time && $endTime <= $openingHour->close_time;
    }

    /**
     * Check if time is blocked by owner
     */
    public function isTimeBlocked(
        int $studioId,
        ?int $roomId,
        string $date,
        string $startTime,
        string $endTime
    ): bool {
        $query = BlockedSchedule::where('studio_id', $studioId)
            ->where(function ($q) use ($date, $startTime, $endTime) {
                // All-day block for the date
                $q->where(function ($q2) use ($date) {
                    $q2->whereDate('date', $date)
                       ->where('all_day', true);
                })
                // Or time-range block that overlaps
                ->orWhere(function ($q2) use ($date, $startTime, $endTime) {
                    $q2->whereDate('date', $date)
                       ->where('all_day', false)
                       ->where('start_time', '<', $endTime)
                       ->where('end_time', '>', $startTime);
                });
            })
            ->where(function ($q) use ($roomId) {
                // Global block (no specific room) or room-specific block
                $q->whereNull('room_id')
                  ->orWhere('room_id', $roomId);
            });

        return $query->exists();
    }

    /**
     * Check if there's an overlapping booking
     */
    public function hasOverlappingBooking(
        int $roomId,
        string $date,
        string $startTime,
        string $endTime,
        ?int $excludeBookingId = null
    ): bool {
        $query = Booking::where('room_id', $roomId)
            ->whereDate('date', $date)
            ->whereNotIn('status', ['cancelled', 'failed', 'expired'])
            ->where('start_time', '<', $endTime)
            ->where('end_time', '>', $startTime);

        if ($excludeBookingId) {
            $query->where('id', '!=', $excludeBookingId);
        }

        return $query->exists();
    }

    /**
     * Get available time slots for a room on a specific date
     */
    public function getAvailableSlots(int $roomId, string $date, int $durationHours = 1): array
    {
        $room = StudioRoom::findOrFail($roomId);
        $studio = $room->studio;
        $dayOfWeek = Carbon::parse($date)->dayOfWeek;

        // Get opening hours
        $openingHour = OpeningHour::where('studio_id', $studio->id)
            ->where('day_of_week', $dayOfWeek)
            ->first();

        if (!$openingHour || $openingHour->is_closed) {
            return [];
        }

        // Get blocked times
        $blockedTimes = BlockedSchedule::where('studio_id', $studio->id)
            ->whereDate('date', $date)
            ->where(function ($q) use ($roomId) {
                $q->whereNull('room_id')
                  ->orWhere('room_id', $roomId);
            })
            ->where('all_day', true)
            ->get();

        // If entire day is blocked
        if ($blockedTimes->isNotEmpty()) {
            return [];
        }

        // Get time blocks
        $timeBlocks = BlockedSchedule::where('studio_id', $studio->id)
            ->whereDate('date', $date)
            ->where('all_day', false)
            ->where(function ($q) use ($roomId) {
                $q->whereNull('room_id')
                  ->orWhere('room_id', $roomId);
            })
            ->get(['start_time', 'end_time']);

        // Get existing bookings
        $bookings = Booking::where('room_id', $roomId)
            ->whereDate('date', $date)
            ->whereNotIn('status', ['cancelled', 'failed', 'expired'])
            ->get(['start_time', 'end_time']);

        // Combine blocked times and bookings
        $occupiedSlots = $timeBlocks->concat($bookings)->map(function ($item) {
            return [
                'start' => $item->start_time,
                'end' => $item->end_time,
            ];
        })->toArray();

        // Generate available slots
        $slots = [];
        $openTime = Carbon::parse($openingHour->open_time);
        $closeTime = Carbon::parse($openingHour->close_time);

        while ($openTime->copy()->addHours($durationHours)->lte($closeTime)) {
            $slotStart = $openTime->format('H:i:s');
            $slotEnd = $openTime->copy()->addHours($durationHours)->format('H:i:s');

            $isAvailable = true;
            foreach ($occupiedSlots as $occupied) {
                if ($slotStart < $occupied['end'] && $slotEnd > $occupied['start']) {
                    $isAvailable = false;
                    break;
                }
            }

            $slots[] = [
                'start_time' => $slotStart,
                'end_time' => $slotEnd,
                'is_available' => $isAvailable,
            ];

            $openTime->addHour();
        }

        return $slots;
    }

    /**
     * Get available rooms for a specific date and time
     */
    public function getAvailableRooms(int $studioId, string $date, string $startTime, string $endTime): array
    {
        $studio = Studio::findOrFail($studioId);
        
        $rooms = $studio->rooms()->where('is_active', true)->get();
        
        $availableRooms = [];
        
        foreach ($rooms as $room) {
            if ($this->isRoomAvailable($room->id, $date, $startTime, $endTime)) {
                $availableRooms[] = $room;
            }
        }
        
        return $availableRooms;
    }

    /**
     * Get blocked schedule summary for a date range
     */
    public function getBlockedDates(int $studioId, ?int $roomId, string $startDate, string $endDate): array
    {
        $query = BlockedSchedule::where('studio_id', $studioId)
            ->whereBetween('date', [$startDate, $endDate]);

        if ($roomId) {
            $query->where(function ($q) use ($roomId) {
                $q->whereNull('room_id')
                  ->orWhere('room_id', $roomId);
            });
        }

        return $query->get()->groupBy('date')->map(function ($blocks, $date) {
            $allDay = $blocks->contains('all_day', true);
            return [
                'date' => $date,
                'is_all_day_blocked' => $allDay,
                'blocks' => $allDay ? [] : $blocks->map(fn($b) => [
                    'start_time' => $b->start_time,
                    'end_time' => $b->end_time,
                    'reason' => $b->reason,
                ])->toArray(),
            ];
        })->values()->toArray();
    }
}
