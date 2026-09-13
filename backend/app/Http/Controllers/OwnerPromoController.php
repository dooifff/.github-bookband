<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Promo;
use App\Models\Studio;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class OwnerPromoController extends Controller
{
    /**
     * Get the studio IDs owned by the authenticated user
     */
    private function ownerStudioIds(Request $request)
    {
        return Studio::where('owner_id', $request->user()->id)->pluck('id');
    }

    /**
     * Check whether a promo belongs to one of the owner's studios
     */
    private function isOwnerPromo(Request $request, Promo $promo): bool
    {
        return $this->ownerStudioIds($request)->contains($promo->studio_id);
    }

    /**
     * List promos for the owner's studios
     */
    public function index(Request $request): JsonResponse
    {
        $query = Promo::with('studio')
            ->whereIn('studio_id', $this->ownerStudioIds($request));

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('code', 'like', "%{$search}%")
                  ->orWhere('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Filter by status
        if ($request->has('status')) {
            match ($request->status) {
                'active' => $query->where('is_active', true)
                    ->where('start_date', '<=', now())
                    ->where('end_date', '>=', now()),
                'inactive' => $query->where('is_active', false),
                'expired' => $query->where('end_date', '<', now()),
                'upcoming' => $query->where('start_date', '>', now()),
                default => null,
            };
        }

        // Filter by type
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Sort
        $sortBy = $request->get('sort', 'created_at');
        $sortDir = $request->get('direction', 'desc');
        $query->orderBy($sortBy, $sortDir);

        $promos = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => $promos->items(),
            'meta' => [
                'current_page' => $promos->currentPage(),
                'last_page' => $promos->lastPage(),
                'per_page' => $promos->perPage(),
                'total' => $promos->total(),
            ],
        ]);
    }

    /**
     * Get promo statistics for the owner's studios
     */
    public function stats(Request $request): JsonResponse
    {
        $ownerStudioIds = $this->ownerStudioIds($request);

        $total = Promo::whereIn('studio_id', $ownerStudioIds)->count();
        $active = Promo::whereIn('studio_id', $ownerStudioIds)
            ->where('is_active', true)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->count();
        $expired = Promo::whereIn('studio_id', $ownerStudioIds)
            ->where('end_date', '<', now())
            ->count();
        $inactive = Promo::whereIn('studio_id', $ownerStudioIds)
            ->where('is_active', false)
            ->count();

        $totalUsage = Promo::whereIn('studio_id', $ownerStudioIds)->sum('usage_count');
        $promoIds = Promo::whereIn('studio_id', $ownerStudioIds)->pluck('id');
        $totalDiscount = Booking::whereIn('promo_id', $promoIds)
            ->sum('discount_amount');

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $total,
                'active' => $active,
                'expired' => $expired,
                'inactive' => $inactive,
                'total_usage' => $totalUsage,
                'total_discount' => $totalDiscount ?? 0,
            ],
        ]);
    }

    /**
     * Get single promo details
     */
    public function show(Request $request, Promo $promo): JsonResponse
    {
        if (!$this->isOwnerPromo($request, $promo)) {
            return response()->json([
                'success' => false,
                'message' => 'Promo tidak ditemukan',
            ], 404);
        }

        $promo->load('studio');

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $promo->id,
                'code' => $promo->code,
                'name' => $promo->name,
                'description' => $promo->description,
                'type' => $promo->type,
                'value' => $promo->value,
                'formatted_value' => $promo->type === 'percentage'
                    ? $promo->value . '%'
                    : 'Rp ' . number_format($promo->value, 0, ',', '.'),
                'min_booking_amount' => $promo->min_booking_amount,
                'max_discount' => $promo->max_discount,
                'usage_limit' => $promo->usage_limit,
                'usage_count' => $promo->usage_count,
                'per_user_limit' => $promo->per_user_limit,
                'start_date' => $promo->start_date->toDateString(),
                'end_date' => $promo->end_date->toDateString(),
                'is_active' => $promo->is_active,
                'studio_id' => $promo->studio_id,
                'studio' => $promo->studio ? [
                    'id' => $promo->studio->id,
                    'name' => $promo->studio->name,
                ] : null,
                'remaining_uses' => $promo->usage_limit
                    ? $promo->usage_limit - $promo->usage_count
                    : null,
                'is_valid' => $promo->isValid(),
                'created_at' => $promo->created_at->toDateTimeString(),
                'updated_at' => $promo->updated_at->toDateTimeString(),
            ],
        ]);
    }

    /**
     * Create new promo for one of the owner's studios
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:20|unique:promos,code',
            'name' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'type' => 'required|in:percentage,fixed',
            'value' => 'required|numeric|min:0',
            'min_booking_amount' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit' => 'nullable|integer|min:1',
            'per_user_limit' => 'nullable|integer|min:1',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'studio_id' => 'required|exists:studios,id',
            'is_active' => 'boolean',
        ]);

        // The studio must belong to the owner
        $studio = Studio::find($validated['studio_id']);
        if (!$studio || $studio->owner_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Studio tidak ditemukan',
            ], 422);
        }

        // Auto-generate code if not provided
        if (empty($validated['code'])) {
            $validated['code'] = strtoupper(Str::random(8));
        } else {
            $validated['code'] = strtoupper($validated['code']);
        }

        // Validate percentage value
        if ($validated['type'] === 'percentage' && $validated['value'] > 100) {
            return response()->json([
                'success' => false,
                'message' => 'Persentase diskon tidak boleh lebih dari 100%',
            ], 422);
        }

        $promo = Promo::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Promo berhasil dibuat',
            'data' => $promo,
        ], 201);
    }

    /**
     * Update promo
     */
    public function update(Request $request, Promo $promo): JsonResponse
    {
        if (!$this->isOwnerPromo($request, $promo)) {
            return response()->json([
                'success' => false,
                'message' => 'Promo tidak ditemukan',
            ], 404);
        }

        $validated = $request->validate([
            'code' => 'sometimes|string|max:20|unique:promos,code,' . $promo->id,
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string|max:500',
            'type' => 'sometimes|in:percentage,fixed',
            'value' => 'sometimes|numeric|min:0',
            'min_booking_amount' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit' => 'nullable|integer|min:1',
            'per_user_limit' => 'nullable|integer|min:1',
            'start_date' => 'sometimes|date',
            'end_date' => 'sometimes|date|after_or_equal:start_date',
            'studio_id' => 'sometimes|exists:studios,id',
            'is_active' => 'boolean',
        ]);

        // The studio must belong to the owner
        if (isset($validated['studio_id'])) {
            $studio = Studio::find($validated['studio_id']);
            if (!$studio || $studio->owner_id !== $request->user()->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Studio tidak ditemukan',
                ], 422);
            }
        }

        // Uppercase code
        if (isset($validated['code'])) {
            $validated['code'] = strtoupper($validated['code']);
        }

        // Validate percentage value
        if (isset($validated['type']) && $validated['type'] === 'percentage') {
            $value = $validated['value'] ?? $promo->value;
            if ($value > 100) {
                return response()->json([
                    'success' => false,
                    'message' => 'Persentase diskon tidak boleh lebih dari 100%',
                ], 422);
            }
        }

        $promo->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Promo berhasil diperbarui',
            'data' => $promo,
        ]);
    }

    /**
     * Delete promo
     */
    public function destroy(Request $request, Promo $promo): JsonResponse
    {
        if (!$this->isOwnerPromo($request, $promo)) {
            return response()->json([
                'success' => false,
                'message' => 'Promo tidak ditemukan',
            ], 404);
        }

        // Check if promo has been used
        if ($promo->usage_count > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Promo yang sudah digunakan tidak dapat dihapus. Nonaktifkan saja.',
            ], 422);
        }

        $promo->delete();

        return response()->json([
            'success' => true,
            'message' => 'Promo berhasil dihapus',
        ]);
    }

    /**
     * Toggle promo active status
     */
    public function toggle(Request $request, Promo $promo): JsonResponse
    {
        if (!$this->isOwnerPromo($request, $promo)) {
            return response()->json([
                'success' => false,
                'message' => 'Promo tidak ditemukan',
            ], 404);
        }

        $promo->update(['is_active' => !$promo->is_active]);

        return response()->json([
            'success' => true,
            'message' => $promo->is_active ? 'Promo diaktifkan' : 'Promo dinonaktifkan',
            'data' => ['is_active' => $promo->is_active],
        ]);
    }

    /**
     * Generate unique promo code
     */
    public function generateCode(): JsonResponse
    {
        $code = strtoupper(Str::random(8));

        // Ensure uniqueness
        while (Promo::where('code', $code)->exists()) {
            $code = strtoupper(Str::random(8));
        }

        return response()->json([
            'success' => true,
            'data' => ['code' => $code],
        ]);
    }

    /**
     * Get the owner's studios for promo assignment
     */
    public function studios(Request $request): JsonResponse
    {
        $studios = Studio::where('owner_id', $request->user()->id)
            ->where('is_active', true)
            ->select('id', 'name', 'city')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $studios,
        ]);
    }
}