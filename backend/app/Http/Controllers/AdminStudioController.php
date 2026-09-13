<?php

namespace App\Http\Controllers;

use App\Models\Studio;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminStudioController extends Controller
{
    /**
     * Get all studios with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = Studio::with('owner:id,name,email');

        // Subscription filter
        if ($request->has('subscription_status')) {
            $query->where('subscription_status', $request->subscription_status);
        }

        // Search filter
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('city', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%");
            });
        }

        // Status filter
        if ($request->has('is_verified')) {
            $query->where('is_verified', $request->boolean('is_verified'));
        }

        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        // City filter
        if ($request->has('city')) {
            $query->where('city', $request->city);
        }

        $studios = $query->withCount('rooms')->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $studios->map(fn($studio) => [
                'id' => $studio->id,
                'name' => $studio->name,
                'slug' => $studio->slug,
                'city' => $studio->city,
                'address' => $studio->address,
                'owner' => $studio->owner,
                'is_verified' => $studio->is_verified,
                'is_active' => $studio->is_active,
                'average_rating' => $studio->average_rating,
                'total_reviews' => $studio->total_reviews,
                'rooms_count' => $studio->rooms_count,
                'subscription' => [
                    'status' => $studio->subscription_status,
                    'expires_at' => $studio->subscription_expires_at?->toISOString(),
                    'warning_level' => $studio->subscription_warning_level,
                    'last_warning_at' => $studio->subscription_last_warning_at?->toISOString(),
                ],
                'created_at' => $studio->created_at->toISOString(),
            ]),
            'meta' => [
                'current_page' => $studios->currentPage(),
                'last_page' => $studios->lastPage(),
                'per_page' => $studios->perPage(),
                'total' => $studios->total(),
            ],
        ]);
    }

    /**
     * Get studio detail
     */
    public function show(Studio $studio): JsonResponse
    {
        $studio->load(['owner:id,name,email,phone', 'rooms', 'images']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $studio->id,
                'name' => $studio->name,
                'slug' => $studio->slug,
                'description' => $studio->description,
                'address' => $studio->address,
                'city' => $studio->city,
                'province' => $studio->province,
                'latitude' => $studio->latitude,
                'longitude' => $studio->longitude,
                'phone' => $studio->phone,
                'email' => $studio->email,
                'owner' => $studio->owner,
                'is_verified' => $studio->is_verified,
                'is_active' => $studio->is_active,
                'average_rating' => $studio->average_rating,
                'total_reviews' => $studio->total_reviews,
                'subscription' => [
                    'status' => $studio->subscription_status,
                    'expires_at' => $studio->subscription_expires_at?->toISOString(),
                    'warning_level' => $studio->subscription_warning_level,
                    'last_warning_at' => $studio->subscription_last_warning_at?->toISOString(),
                ],
                'rooms' => $studio->rooms,
                'images' => $studio->images,
                'created_at' => $studio->created_at->toISOString(),
            ],
        ]);
    }

    /**
     * Verify a studio
     */
    public function verify(Studio $studio): JsonResponse
    {
        if ($studio->is_verified) {
            return response()->json([
                'success' => false,
                'message' => 'Studio sudah terverifikasi',
            ], 422);
        }

        $studio->update([
            'is_verified' => true,
            'verified_at' => now(),
        ]);

        // Send notification to studio owner
        \App\Models\Notification::create([
            'user_id' => $studio->owner_id,
            'type' => 'studio_verification',
            'title' => 'Studio Terverifikasi',
            'body' => "Studio \"{$studio->name}\" Anda telah berhasil diverifikasi oleh admin",
            'data' => [
                'studio_id' => $studio->id,
                'studio_name' => $studio->name,
                'action' => 'verified',
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Studio berhasil diverifikasi',
            'data' => [
                'id' => $studio->id,
                'is_verified' => true,
                'verified_at' => $studio->verified_at->toISOString(),
            ],
        ]);
    }

    /**
     * Unverify a studio
     */
    public function unverify(Studio $studio): JsonResponse
    {
        $studio->update([
            'is_verified' => false,
            'verified_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Verifikasi studio dibatalkan',
        ]);
    }

    /**
     * Deactivate a studio
     */
    public function deactivate(Studio $studio): JsonResponse
    {
        $studio->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Studio berhasil dinonaktifkan',
        ]);
    }

    /**
     * Activate a studio
     */
    public function activate(Studio $studio): JsonResponse
    {
        $studio->update(['is_active' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Studio berhasil diaktifkan',
        ]);
    }

    /**
     * Get studios pending verification
     */
    public function pendingVerification(): JsonResponse
    {
        $studios = Studio::where('is_verified', false)
            ->with('owner:id,name,email')
            ->orderBy('created_at', 'asc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $studios->map(fn($studio) => [
                'id' => $studio->id,
                'name' => $studio->name,
                'city' => $studio->city,
                'address' => $studio->address,
                'owner' => $studio->owner,
                'created_at' => $studio->created_at->toISOString(),
            ]),
            'meta' => [
                'current_page' => $studios->currentPage(),
                'last_page' => $studios->lastPage(),
                'per_page' => $studios->perPage(),
                'total' => $studios->total(),
            ],
        ]);
    }

    /**
     * Get studio statistics
     */
    public function stats(): JsonResponse
    {
        $totalStudios = Studio::count();
        $verified = Studio::where('is_verified', true)->count();
        $unverified = Studio::where('is_verified', false)->count();
        $active = Studio::where('is_active', true)->count();
        $inactive = Studio::where('is_active', false)->count();

        $byCity = Studio::selectRaw('city, COUNT(*) as count')
            ->groupBy('city')
            ->orderByDesc('count')
            ->limit(10)
            ->pluck('count', 'city');

        $recentStudios = Studio::where('created_at', '>=', now()->subDays(30))
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $totalStudios,
                'verified' => $verified,
                'unverified' => $unverified,
                'active' => $active,
                'inactive' => $inactive,
                'by_city' => $byCity,
                'recent_registrations' => $recentStudios,
            ],
        ]);
    }
}
