<?php

namespace App\Http\Controllers;

use App\Services\BulkScheduleService;
use App\Models\StudioRoom;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BulkScheduleController extends Controller
{
    public function __construct(
        private BulkScheduleService $bulkScheduleService
    ) {}

    /**
     * Block multiple dates for a room
     */
    public function blockDates(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'dates' => 'required|array|min:1',
            'dates.*' => 'date|after_or_equal:today',
            'reason' => 'nullable|string|max:255',
        ]);

        $room = StudioRoom::findOrFail($request->room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke ruangan ini',
            ], 403);
        }

        try {
            $blocked = $this->bulkScheduleService->blockDates(
                $request->room_id,
                $request->dates,
                $request->reason
            );

            return response()->json([
                'success' => true,
                'message' => count($blocked) . ' tanggal berhasil diblokir',
                'data' => $blocked,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Block date range for a room
     */
    public function blockDateRange(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'start_date' => 'required|date|after_or_equal:today',
            'end_date' => 'required|date|after_or_equal:start_date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after:start_time',
            'reason' => 'nullable|string|max:255',
        ]);

        $room = StudioRoom::findOrFail($request->room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke ruangan ini',
            ], 403);
        }

        try {
            $blocked = $this->bulkScheduleService->blockDateRange(
                $request->room_id,
                $request->start_date,
                $request->end_date,
                $request->start_time,
                $request->end_time,
                $request->reason
            );

            return response()->json([
                'success' => true,
                'message' => count($blocked) . ' tanggal berhasil diblokir',
                'data' => $blocked,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Block recurring schedule (weekly)
     */
    public function blockRecurring(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'days_of_week' => 'required|array|min:1',
            'days_of_week.*' => 'integer|min:0|max:6',
            'start_date' => 'required|date|after_or_equal:today',
            'end_date' => 'required|date|after_or_equal:start_date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after:start_time',
            'reason' => 'nullable|string|max:255',
        ]);

        $room = StudioRoom::findOrFail($request->room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke ruangan ini',
            ], 403);
        }

        try {
            $blocked = $this->bulkScheduleService->blockRecurring(
                $request->room_id,
                $request->days_of_week,
                $request->start_date,
                $request->end_date,
                $request->start_time,
                $request->end_time,
                $request->reason
            );

            return response()->json([
                'success' => true,
                'message' => count($blocked) . ' tanggal berhasil diblokir secara berulang',
                'data' => $blocked,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Block multiple rooms for same dates
     */
    public function blockMultipleRooms(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_ids' => 'required|array|min:1',
            'room_ids.*' => 'exists:studio_rooms,id',
            'dates' => 'required|array|min:1',
            'dates.*' => 'date|after_or_equal:today',
            'reason' => 'nullable|string|max:255',
        ]);

        // Check ownership for all rooms
        foreach ($request->room_ids as $roomId) {
            $room = StudioRoom::findOrFail($roomId);
            if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak memiliki akses ke salah satu ruangan',
                ], 403);
            }
        }

        try {
            $blocked = $this->bulkScheduleService->blockMultipleRooms(
                $request->room_ids,
                $request->dates,
                $request->reason
            );

            return response()->json([
                'success' => true,
                'message' => count($blocked) . ' blokir berhasil dibuat',
                'data' => $blocked,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Remove blocked schedules in bulk
     */
    public function removeBulk(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'blocked_ids' => 'required|array|min:1',
            'blocked_ids.*' => 'exists:blocked_schedules,id',
        ]);

        // Check ownership for all blocked schedules
        foreach ($request->blocked_ids as $blockedId) {
            $blocked = \App\Models\BlockedSchedule::findOrFail($blockedId);
            if (!$user->ownedStudios()->where('id', $blocked->studio_id)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak memiliki akses ke salah satu blokir',
                ], 403);
            }
        }

        $count = $this->bulkScheduleService->removeBulk($request->blocked_ids);

        return response()->json([
            'success' => true,
            'message' => $count . ' blokir berhasil dihapus',
        ]);
    }

    /**
     * Remove blocked schedules by date range
     */
    public function removeByDateRange(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        $room = StudioRoom::findOrFail($request->room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke ruangan ini',
            ], 403);
        }

        $count = $this->bulkScheduleService->removeByDateRange(
            $request->room_id,
            $request->start_date,
            $request->end_date
        );

        return response()->json([
            'success' => true,
            'message' => $count . ' blokir berhasil dihapus',
        ]);
    }

    /**
     * Get blocked schedules summary
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        $room = StudioRoom::findOrFail($request->room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke ruangan ini',
            ], 403);
        }

        $summary = $this->bulkScheduleService->getBlockedSummary(
            $request->room_id,
            $request->start_date,
            $request->end_date
        );

        return response()->json([
            'success' => true,
            'data' => $summary,
        ]);
    }
}
