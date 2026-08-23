<?php

namespace App\Http\Controllers;

use App\Services\ScheduleService;
use App\Models\Studio;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    protected $scheduleService;

    public function __construct(ScheduleService $scheduleService)
    {
        $this->scheduleService = $scheduleService;
    }

    /**
     * Check room availability
     */
    public function checkAvailability(Request $request, int $studioId): JsonResponse
    {
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'date' => 'required|date|after_or_equal:today',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
        ]);

        $studio = Studio::findOrFail($studioId);

        // Verify room belongs to studio
        $room = $studio->rooms()->find($request->room_id);
        if (!$room) {
            return $this->errorResponse('Ruangan tidak ditemukan di studio ini', 404);
        }

        $isAvailable = $this->scheduleService->isRoomAvailable(
            $request->room_id,
            $request->date,
            $request->start_time,
            $request->end_time
        );

        return $this->successResponse([
            'is_available' => $isAvailable,
            'room_id' => $request->room_id,
            'date' => $request->date,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'message' => $isAvailable ? 'Ruangan tersedia' : 'Ruangan tidak tersedia',
        ]);
    }

    /**
     * Get available time slots for a room
     */
    public function getAvailableSlots(Request $request, int $studioId): JsonResponse
    {
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'date' => 'required|date|after_or_equal:today',
            'duration_hours' => 'nullable|integer|min:1|max:12',
        ]);

        $studio = Studio::findOrFail($studioId);

        // Verify room belongs to studio
        $room = $studio->rooms()->find($request->room_id);
        if (!$room) {
            return $this->errorResponse('Ruangan tidak ditemukan di studio ini', 404);
        }

        $slots = $this->scheduleService->getAvailableSlots(
            $request->room_id,
            $request->date,
            $request->get('duration_hours', 1)
        );

        return $this->successResponse([
            'room_id' => $request->room_id,
            'date' => $request->date,
            'duration_hours' => $request->get('duration_hours', 1),
            'slots' => $slots,
            'total_slots' => count($slots),
            'available_slots' => count(array_filter($slots, fn($s) => $s['is_available'])),
        ]);
    }

    /**
     * Get available rooms for a specific date and time
     */
    public function getAvailableRooms(Request $request, int $studioId): JsonResponse
    {
        $request->validate([
            'date' => 'required|date|after_or_equal:today',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
        ]);

        $studio = Studio::findOrFail($studioId);

        $rooms = $this->scheduleService->getAvailableRooms(
            $studioId,
            $request->date,
            $request->start_time,
            $request->end_time
        );

        return $this->successResponse([
            'studio_id' => $studioId,
            'date' => $request->date,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'rooms' => $rooms->map(fn($room) => [
                'id' => $room->id,
                'name' => $room->name,
                'capacity' => $room->capacity,
                'price_per_hour' => $room->price_per_hour,
                'formatted_price' => $room->formatted_price,
            ]),
            'total_available' => $rooms->count(),
        ]);
    }

    /**
     * Get studio schedule summary for a month
     */
    public function getMonthlySchedule(Request $request, int $studioId): JsonResponse
    {
        $request->validate([
            'month' => 'required|integer|between:1,12',
            'year' => 'required|integer|min:2024|max:2030',
            'room_id' => 'nullable|exists:studio_rooms,id',
        ]);

        $studio = Studio::findOrFail($studioId);

        $startDate = sprintf('%04d-%02d-01', $request->year, $request->month);
        $endDate = Carbon::parse($startDate)->endOfMonth()->format('Y-m-d');

        $blockedDates = $this->scheduleService->getBlockedDates(
            $studioId,
            $request->room_id,
            $startDate,
            $endDate
        );

        // Get booking count per day
        $bookingQuery = $studio->bookings()
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'failed', 'expired']);

        if ($request->room_id) {
            $bookingQuery->where('room_id', $request->room_id);
        }

        $bookingStats = $bookingQuery
            ->selectRaw('date, COUNT(*) as booking_count')
            ->groupBy('date')
            ->pluck('booking_count', 'date');

        return $this->successResponse([
            'studio_id' => $studioId,
            'month' => $request->month,
            'year' => $request->year,
            'blocked_dates' => $blockedDates,
            'booking_stats' => $bookingStats,
        ]);
    }
}
