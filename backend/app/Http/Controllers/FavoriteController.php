<?php

namespace App\Http\Controllers;

use App\Models\Favorite;
use App\Models\Studio;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FavoriteController extends Controller
{
    /**
     * Get user's favorites
     */
    public function index(Request $request): JsonResponse
    {
        $favorites = Favorite::where('user_id', $request->user()->id)
            ->with(['studio' => function ($q) {
                $q->select('id', 'name', 'slug', 'address', 'city', 'average_rating', 'total_reviews');
            }, 'studio.images' => function ($q) {
                $q->select('id', 'studio_id', 'url')->where('is_primary', true)->limit(1);
            }])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $favorites->map(function ($favorite) {
                return [
                    'id' => $favorite->id,
                    'studio' => [
                        'id' => $favorite->studio->id,
                        'name' => $favorite->studio->name,
                        'slug' => $favorite->studio->slug,
                        'address' => $favorite->studio->address,
                        'city' => $favorite->studio->city,
                        'average_rating' => $favorite->studio->average_rating,
                        'total_reviews' => $favorite->studio->total_reviews,
                        'thumbnail' => $favorite->studio->images->first()?->url ?? null,
                    ],
                    'created_at' => $favorite->created_at->toISOString(),
                ];
            }),
            'meta' => [
                'current_page' => $favorites->currentPage(),
                'last_page' => $favorites->lastPage(),
                'per_page' => $favorites->perPage(),
                'total' => $favorites->total(),
            ],
        ]);
    }

    /**
     * Add studio to favorites
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'studio_id' => 'required|exists:studios,id',
        ]);

        $user = $request->user();

        // Check if already favorited
        $existing = Favorite::where('user_id', $user->id)
            ->where('studio_id', $request->studio_id)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Studio sudah ada di favorit',
            ], 409);
        }

        $favorite = Favorite::create([
            'user_id' => $user->id,
            'studio_id' => $request->studio_id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Studio berhasil ditambahkan ke favorit',
            'data' => [
                'id' => $favorite->id,
                'studio_id' => $favorite->studio_id,
                'created_at' => $favorite->created_at->toISOString(),
            ],
        ], 201);
    }

    /**
     * Remove studio from favorites
     */
    public function destroy(Request $request, int $studioId): JsonResponse
    {
        $user = $request->user();

        $favorite = Favorite::where('user_id', $user->id)
            ->where('studio_id', $studioId)
            ->first();

        if (!$favorite) {
            return response()->json([
                'success' => false,
                'message' => 'Studio tidak ada di favorit',
            ], 404);
        }

        $favorite->delete();

        return response()->json([
            'success' => true,
            'message' => 'Studio berhasil dihapus dari favorit',
        ]);
    }

    /**
     * Check if studio is favorited by user
     */
    public function check(Request $request, int $studioId): JsonResponse
    {
        $isFavorited = Favorite::where('user_id', $request->user()->id)
            ->where('studio_id', $studioId)
            ->exists();

        return response()->json([
            'success' => true,
            'data' => [
                'is_favorited' => $isFavorited,
            ],
        ]);
    }

    /**
     * Toggle favorite status
     */
    public function toggle(Request $request): JsonResponse
    {
        $request->validate([
            'studio_id' => 'required|exists:studios,id',
        ]);

        $user = $request->user();
        $studioId = $request->studio_id;

        $favorite = Favorite::where('user_id', $user->id)
            ->where('studio_id', $studioId)
            ->first();

        if ($favorite) {
            $favorite->delete();
            $message = 'Studio berhasil dihapus dari favorit';
            $isFavorited = false;
        } else {
            Favorite::create([
                'user_id' => $user->id,
                'studio_id' => $studioId,
            ]);
            $message = 'Studio berhasil ditambahkan ke favorit';
            $isFavorited = true;
        }

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => [
                'is_favorited' => $isFavorited,
            ],
        ]);
    }
}
