<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreBlockedScheduleRequest;
use App\Http\Resources\BlockedScheduleResource;
use App\Models\BlockedSchedule;
use App\Models\Studio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BlockedScheduleController extends Controller
{
    /**
     * List blocked schedules for a studio
     */
    public function index(Request $request, int $studioId)
    {
        $studio = Studio::findOrFail($studioId);

        $query = $studio->blockedSchedules()->with('room');

        // Filter by date range
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('date', [$request->start_date, $request->end_date]);
        } elseif ($request->has('month')) {
            $query->whereMonth('date', $request->month)
                  ->whereYear('date', $request->year ?? now()->year);
        }

        // Filter by room
        if ($request->has('room_id')) {
            $query->where(function ($q) use ($request) {
                $q->where('room_id', $request->room_id)
                  ->orWhereNull('room_id');
            });
        }

        $blockedSchedules = $query->orderBy('date', 'desc')
            ->orderBy('start_time')
            ->paginate(50);

        return response()->json([
            'success' => true,
            'message' => 'Blocked schedules retrieved successfully',
            'data' => BlockedScheduleResource::collection($blockedSchedules),
            'meta' => [
                'current_page' => $blockedSchedules->currentPage(),
                'last_page' => $blockedSchedules->lastPage(),
                'per_page' => $blockedSchedules->perPage(),
                'total' => $blockedSchedules->total(),
            ],
        ]);
    }

    /**
     * Store new blocked schedule (owner only)
     */
    public function store(StoreBlockedScheduleRequest $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        // Verify room belongs to studio if provided
        if ($request->room_id) {
            $room = $studio->rooms()->find($request->room_id);
            if (!$room) {
                return $this->errorResponse('Ruangan tidak ditemukan di studio ini', 404);
            }
        }

        // Check for overlapping blocked schedules
        $hasOverlap = BlockedSchedule::where('studio_id', $studioId)
            ->where('date', $request->date)
            ->where(function ($q) use ($request) {
                $q->whereNull('room_id')
                  ->orWhere('room_id', $request->room_id);
            })
            ->where(function ($q) use ($request) {
                if ($request->all_day) {
                    $q->where('all_day', true);
                } else {
                    $q->where(function ($q2) use ($request) {
                        $q2->where('all_day', true)
                          ->orWhere(function ($q3) use ($request) {
                              $q3->where('start_time', '<', $request->end_time)
                                ->where('end_time', '>', $request->start_time);
                          });
                    });
                }
            })
            ->exists();

        if ($hasOverlap) {
            return $this->errorResponse('Jadwal bertambah dengan jadwal yang sudah ada', 400);
        }

        $blockedSchedule = BlockedSchedule::create([
            'studio_id' => $studioId,
            'room_id' => $request->room_id,
            'date' => $request->date,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'all_day' => $request->get('all_day', false),
            'reason' => $request->reason,
        ]);

        return $this->successResponse(
            new BlockedScheduleResource($blockedSchedule->load('room')),
            'Jadwal blokir berhasil dibuat',
            201
        );
    }

    /**
     * Update blocked schedule (owner only)
     */
    public function update(StoreBlockedScheduleRequest $request, int $studioId, int $id): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $blockedSchedule = $studio->blockedSchedules()->findOrFail($id);

        $blockedSchedule->update([
            'room_id' => $request->room_id ?? $blockedSchedule->room_id,
            'date' => $request->date ?? $blockedSchedule->date,
            'start_time' => $request->start_time ?? $blockedSchedule->start_time,
            'end_time' => $request->end_time ?? $blockedSchedule->end_time,
            'all_day' => $request->get('all_day', $blockedSchedule->all_day),
            'reason' => $request->reason ?? $blockedSchedule->reason,
        ]);

        return $this->successResponse(
            new BlockedScheduleResource($blockedSchedule->fresh()->load('room')),
            'Jadwal blokir berhasil diperbarui'
        );
    }

    /**
     * Delete blocked schedule (owner only)
     */
    public function destroy(Request $request, int $studioId, int $id): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $blockedSchedule = $studio->blockedSchedules()->findOrFail($id);
        $blockedSchedule->delete();

        return $this->successResponse(null, 'Jadwal blokir berhasil dihapus');
    }

    /**
     * Bulk delete blocked schedules
     */
    public function bulkDelete(Request $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $request->validate([
            'ids' => ['required', 'array'],
            'ids.*' => ['integer', 'exists:blocked_schedules,id'],
        ]);

        BlockedSchedule::whereIn('id', $request->ids)
            ->where('studio_id', $studioId)
            ->delete();

        return $this->successResponse(null, 'Jadwal blokir berhasil dihapus');
    }
}
