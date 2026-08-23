<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreEquipmentRequest;
use App\Http\Resources\EquipmentResource;
use App\Models\Equipment;
use App\Models\Studio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EquipmentController extends Controller
{
    /**
     * List equipment for a studio
     */
    public function index(Request $request, int $studioId)
    {
        $studio = Studio::findOrFail($studioId);

        $equipment = $studio->equipment()
            ->when(!$request->user() || $request->user()->id !== $studio->owner_id, function ($q) {
                $q->where('is_active', true);
            })
            ->get();

        return $this->successResponse(
            EquipmentResource::collection($equipment),
            'Equipment retrieved successfully'
        );
    }

    /**
     * Store new equipment (owner only)
     */
    public function store(StoreEquipmentRequest $request, int $studioId): JsonResponse
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

        $equipment = $studio->equipment()->create($request->validated());

        return $this->successResponse(
            new EquipmentResource($equipment),
            'Equipment berhasil dibuat',
            201
        );
    }

    /**
     * Update equipment (owner only)
     */
    public function update(StoreEquipmentRequest $request, int $studioId, int $equipmentId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $equipment = $studio->equipment()->findOrFail($equipmentId);
        $equipment->update($request->validated());

        return $this->successResponse(
            new EquipmentResource($equipment->fresh()),
            'Equipment berhasil diperbarui'
        );
    }

    /**
     * Delete equipment (owner only)
     */
    public function destroy(Request $request, int $studioId, int $equipmentId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $equipment = $studio->equipment()->findOrFail($equipmentId);
        $equipment->delete();

        return $this->successResponse(null, 'Equipment berhasil dihapus');
    }
}
