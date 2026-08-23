<?php

namespace App\Http\Controllers;

use App\Services\DynamicPricingService;
use App\Models\DynamicPricingRule;
use App\Models\StudioRoom;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class DynamicPricingController extends Controller
{
    public function __construct(
        private DynamicPricingService $pricingService
    ) {}

    /**
     * Get pricing rules for a room
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
        ]);

        $room = StudioRoom::findOrFail($request->room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke ruangan ini',
            ], 403);
        }

        $rules = DynamicPricingRule::where('studio_room_id', $request->room_id)
            ->orderBy('priority', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $rules,
        ]);
    }

    /**
     * Create a pricing rule
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'multiplier' => 'required|numeric|min:0.1|max:5',
            'priority' => 'nullable|integer|min:0',
            'days_of_week' => 'nullable|array',
            'days_of_week.*' => 'integer|min:0|max:6',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
            'is_active' => 'nullable|boolean',
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
            $rule = $this->pricingService->createRule([
                'studio_room_id' => $request->room_id,
                'name' => $request->name,
                'description' => $request->description,
                'multiplier' => $request->multiplier,
                'priority' => $request->priority ?? 0,
                'days_of_week' => $request->days_of_week,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'start_time' => $request->start_time,
                'end_time' => $request->end_time,
                'is_active' => $request->is_active ?? true,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Aturan harga berhasil dibuat',
                'data' => $rule,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update a pricing rule
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        
        $rule = DynamicPricingRule::findOrFail($id);
        $room = StudioRoom::findOrFail($rule->studio_room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke aturan ini',
            ], 403);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'multiplier' => 'sometimes|numeric|min:0.1|max:5',
            'priority' => 'nullable|integer|min:0',
            'days_of_week' => 'nullable|array',
            'days_of_week.*' => 'integer|min:0|max:6',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
            'is_active' => 'nullable|boolean',
        ]);

        try {
            $updated = $this->pricingService->updateRule($id, $request->only([
                'name', 'description', 'multiplier', 'priority',
                'days_of_week', 'start_date', 'end_date',
                'start_time', 'end_time', 'is_active',
            ]));

            return response()->json([
                'success' => true,
                'message' => 'Aturan harga berhasil diperbarui',
                'data' => $updated,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete a pricing rule
     */
    public function destroy(int $id): JsonResponse
    {
        $user = request()->user();
        
        $rule = DynamicPricingRule::findOrFail($id);
        $room = StudioRoom::findOrFail($rule->studio_room_id);
        
        // Check ownership
        if (!$user->ownedStudios()->where('id', $room->studio_id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke aturan ini',
            ], 403);
        }

        try {
            $this->pricingService->deleteRule($id);

            return response()->json([
                'success' => true,
                'message' => 'Aturan harga berhasil dihapus',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Calculate price for a booking
     */
    public function calculatePrice(Request $request): JsonResponse
    {
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'date' => 'required|date|after_or_equal:today',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
        ]);

        try {
            $pricing = $this->pricingService->calculatePrice(
                $request->room_id,
                $request->date,
                $request->start_time,
                $request->end_time
            );

            return response()->json([
                'success' => true,
                'data' => $pricing,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get pricing preview for a date range
     */
    public function preview(Request $request): JsonResponse
    {
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
        ]);

        try {
            $preview = $this->pricingService->getPricingPreview(
                $request->room_id,
                $request->start_date,
                $request->end_date,
                $request->start_time ?? '09:00',
                $request->end_time ?? '17:00'
            );

            return response()->json([
                'success' => true,
                'data' => $preview,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Create default peak hour rules for a room
     */
    public function createPeakHourRules(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'room_id' => 'required|exists:studio_rooms,id',
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
            $rules = $this->pricingService->createPeakHourRules($request->room_id);

            return response()->json([
                'success' => true,
                'message' => count($rules) . ' aturan harga jam sibuk berhasil dibuat',
                'data' => $rules,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}
