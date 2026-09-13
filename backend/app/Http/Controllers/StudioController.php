<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreStudioRequest;
use App\Http\Requests\UpdateStudioRequest;
use App\Http\Resources\StudioResource;
use App\Models\Studio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class StudioController extends Controller
{
    /**
     * List studios (public - for discovery, with cache for simple queries)
     */
    public function index(Request $request)
    {
        $query = Studio::where('is_active', true)
            ->with(['owner:id,name', 'images' => function ($q) {
                $q->select('id', 'studio_id', 'url')->limit(1);
            }]);

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('city', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%");
            });
        }

        // Filter by city
        if ($request->has('city')) {
            $query->where('city', $request->city);
        }

        // Filter by province
        if ($request->has('province')) {
            $query->where('province', $request->province);
        }

        // Filter by rating
        if ($request->has('min_rating')) {
            $query->where('average_rating', '>=', $request->min_rating);
        }

        // Filter by price range
        if ($request->has('min_price') || $request->has('max_price')) {
            $query->whereHas('rooms', function ($q) use ($request) {
                if ($request->has('min_price')) {
                    $q->where('price_per_hour', '>=', $request->min_price);
                }
                if ($request->has('max_price')) {
                    $q->where('price_per_hour', '<=', $request->max_price);
                }
            });
        }

        // Sort
        $sortField = $request->get('sort_by', 'created_at');
        $sortDirection = strtolower($request->get('sort_direction', 'desc')) === 'asc' ? 'asc' : 'desc';

        // Mobile uses sort_by=rating|popular|price_low|price_high|newest|name
        $sortMap = [
            'rating' => 'average_rating',
            'newest' => 'created_at',
            'popular' => 'total_reviews',
            'price_low' => 'min_price',
            'price_high' => 'max_price',
        ];
        $sortField = $sortMap[$sortField] ?? $sortField;

        $allowedSorts = ['name', 'average_rating', 'created_at', 'total_reviews'];
        if (in_array($sortField, $allowedSorts)) {
            $query->orderBy($sortField, $sortDirection);
        } elseif ($sortField === 'min_price' || $sortField === 'max_price') {
            $priceColumn = $sortField === 'min_price' ? 'min_price' : 'max_price';
            $query->withMin('rooms as min_price', 'price_per_hour')
                ->withMax('rooms as max_price', 'price_per_hour')
                ->orderByRaw("{$priceColumn} IS NULL")
                ->orderBy($priceColumn, $sortField === 'min_price' ? 'asc' : 'desc');
        }

        // Pagination
        $perPage = min($request->get('per_page', $request->get('limit', 20)), 50);
        $studios = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Studios retrieved successfully',
            'data' => StudioResource::collection($studios),
            'meta' => [
                'current_page' => $studios->currentPage(),
                'last_page' => $studios->lastPage(),
                'per_page' => $studios->perPage(),
                'total' => $studios->total(),
            ],
        ]);
    }

    /**
     * Show studio by slug (public)
     */
    public function showBySlug(string $slug)
    {
        $studio = Studio::where('slug', $slug)
            ->where('is_active', true)
            ->with([
                'owner:id,name,avatar',
                'rooms' => function ($q) {
                    $q->where('is_active', true);
                },
                'images',
                'openingHours',
                'equipment' => function ($q) {
                    $q->where('is_active', true);
                },
                'facilities' => function ($q) {
                    $q->where('is_active', true);
                },
            ])
            ->firstOrFail();

        return $this->successResponse(
            new StudioResource($studio),
            'Studio retrieved successfully'
        );
    }

    /**
     * Show studio by ID (owner/admin)
     */
    public function show(int $id)
    {
        $studio = Studio::with([
            'owner:id,name,email,avatar',
            'rooms',
            'images',
            'openingHours',
            'equipment',
            'facilities',
            'promos' => function ($q) {
                $q->where('is_active', true);
            },
        ])->findOrFail($id);

        return $this->successResponse(
            new StudioResource($studio),
            'Studio retrieved successfully'
        );
    }

    /**
     * Store new studio (owner only)
     */
    public function store(StoreStudioRequest $request): JsonResponse
    {
        $studio = Studio::create([
            'owner_id' => $request->user()->id,
            'name' => $request->name,
            'description' => $request->description,
            'address' => $request->address,
            'city' => $request->city,
            'province' => $request->province,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'phone' => $request->phone,
            'email' => $request->email,
            'logo' => $request->logo,
        ]);

        // Invalidate studio caches
        Cache::forget('studios_listing');

        return $this->successResponse(
            new StudioResource($studio->load('owner')),
            'Studio berhasil dibuat',
            201
        );
    }

    /**
     * Update studio (owner only)
     */
    public function update(UpdateStudioRequest $request, int $id): JsonResponse
    {
        $studio = Studio::findOrFail($id);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses untuk mengubah studio ini', 403);
        }

        $data = $request->validated();
        $studio->update($data);

        // Invalidate studio caches
        Cache::forget('studios_listing');

        return $this->successResponse(
            new StudioResource($studio->fresh()),
            'Studio berhasil diperbarui'
        );
    }

    /**
     * Delete studio (owner only, soft delete)
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $studio = Studio::findOrFail($id);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses untuk menghapus studio ini', 403);
        }

        // Check if there are active bookings
        $hasActiveBookings = $studio->bookings()
            ->whereIn('status', ['pending', 'awaiting_payment', 'paid', 'confirmed'])
            ->exists();

        if ($hasActiveBookings) {
            return $this->errorResponse('Tidak dapat menghapus studio dengan booking aktif', 400);
        }

        $studio->delete();

        // Invalidate studio caches
        Cache::forget('studios_listing');

        return $this->successResponse(null, 'Studio berhasil dihapus');
    }

    /**
     * List owner's studios
     */
    public function ownerStudios(Request $request)
    {
        $studios = Studio::where('owner_id', $request->user()->id)
            ->with(['rooms', 'images'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        // Add rooms_count to each studio (since StudioResource doesn't have it)
        $studios->getCollection()->each(function ($studio) {
            $studio->setAttribute('rooms_count', $studio->rooms->count());
            $studio->setAttribute('active_rooms_count', $studio->rooms->where('is_active', true)->count());
        });

        return response()->json([
            'success' => true,
            'message' => 'Studios retrieved successfully',
            'data' => StudioResource::collection($studios),
            'meta' => [
                'current_page' => $studios->currentPage(),
                'last_page' => $studios->lastPage(),
                'per_page' => $studios->perPage(),
                'total' => $studios->total(),
            ],
        ]);
    }

    /**
     * Upload image for owner's studio
     */
    public function uploadImage(Request $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $request->validate([
            'image' => ['required', 'image', 'mimes:jpeg,png,jpg,webp,gif', 'max:5120'],
            'caption' => ['nullable', 'string', 'max:255'],
            'is_primary' => ['sometimes', 'boolean'],
        ]);

        $path = $request->file('image')->store('studio-images', 'public');
        $url = Storage::disk('public')->url($path);

        $image = StudioImage::create([
            'studio_id' => $studioId,
            'url' => $url,
            'caption' => $request->caption,
            'is_primary' => $request->boolean('is_primary', false),
            'sort_order' => 0,
        ]);

        // Invalidate cache
        Cache::forget('studios_listing');

        return $this->successResponse(
            new StudioImageResource($image),
            'Gambar studio berhasil diupload',
            201
        );
    }

    /**
     * Delete studio image
     */
    public function deleteImage(Request $request, int $studioId, int $imageId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $image = StudioImage::where('studio_id', $studioId)->findOrFail($imageId);
        Storage::disk('public')->delete(str_replace(Storage::disk('public')->url('/'), '', $image->url));
        $image->delete();

        Cache::forget('studios_listing');

        return $this->successResponse(null, 'Gambar studio berhasil dihapus');
    }
}
