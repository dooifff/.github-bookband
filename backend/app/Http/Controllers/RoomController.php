<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreRoomRequest;
use App\Http\Requests\UpdateRoomRequest;
use App\Http\Resources\StudioRoomResource;
use App\Models\Studio;
use App\Models\StudioRoom;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoomController extends Controller
{
    /**
     * List rooms for a studio
     */
    public function index(Request $request, int $studioId)
    {
        $studio = Studio::findOrFail($studioId);

        $query = $studio->rooms();

        // Filter by active status (only show active for public)
        if (!$request->user() || $request->user()->id !== $studio->owner_id) {
            $query->where('is_active', true);
        }

        $rooms = $query->with('equipment')->get();

        return $this->successResponse(
            StudioRoomResource::collection($rooms),
            'Rooms retrieved successfully'
        );
    }

    /**
     * Store new room (owner only)
     */
    public function store(StoreRoomRequest $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $room = $studio->rooms()->create($request->validated());

        return $this->successResponse(
            new StudioRoomResource($room),
            'Ruangan berhasil dibuat',
            201
        );
    }

    /**
     * Show room detail
     */
    public function show(int $studioId, int $roomId)
    {
        $studio = Studio::findOrFail($studioId);
        $room = $studio->rooms()->with('equipment')->findOrFail($roomId);

        return $this->successResponse(
            new StudioRoomResource($room),
            'Room retrieved successfully'
        );
    }

    /**
     * Update room (owner only)
     */
    public function update(UpdateRoomRequest $request, int $studioId, int $roomId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $room = $studio->rooms()->findOrFail($roomId);
        $room->update($request->validated());

        return $this->successResponse(
            new StudioRoomResource($room->fresh()),
            'Ruangan berhasil diperbarui'
        );
    }

    /**
     * Delete room (owner only)
     */
    public function destroy(Request $request, int $studioId, int $roomId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $room = $studio->rooms()->findOrFail($roomId);

        // Check if room has active bookings
        $hasActiveBookings = $room->bookings()
            ->whereIn('status', ['pending', 'awaiting_payment', 'paid', 'confirmed'])
            ->exists();

        if ($hasActiveBookings) {
            return $this->errorResponse('Tidak dapat menghapus ruangan dengan booking aktif', 400);
        }

        $room->delete();

        return $this->successResponse(null, 'Ruangan berhasil dihapus');
    }
}
