<?php

namespace App\Http\Controllers;

use App\Models\Review;
use App\Models\Booking;
use App\Models\Studio;
use App\Services\PhotoReviewService;
use App\Services\ProfanityFilter;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ReviewController extends Controller
{
    /**
     * Get reviews for a studio
     */
    public function studioReviews(Request $request, string $slug): JsonResponse
    {
        $studio = Studio::where('slug', $slug)->first();

        if (!$studio) {
            return response()->json([
                'success' => false,
                'message' => 'Studio tidak ditemukan',
            ], 404);
        }

        $reviews = Review::where('studio_id', $studio->id)
            ->with(['user:id,name', 'images'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $reviews->map(function ($review) {
                return [
                    'id' => $review->id,
                    'user' => [
                        'id' => $review->user->id,
                        'name' => $review->is_anonymous ? 'Anonymous' : $review->user->name,
                    ],
                    'rating' => $review->rating,
                    'comment' => ProfanityFilter::censor($review->comment ?? ''),
                    'is_anonymous' => (bool) $review->is_anonymous,
                    'images' => $review->images->map(function ($image) {
                        return [
                            'id' => $image->id,
                            'image_url' => $image->image_url,
                            'caption' => $image->caption,
                        ];
                    }),
                    'created_at' => $review->created_at->toISOString(),
                ];
            }),
            'meta' => [
                'current_page' => $reviews->currentPage(),
                'last_page' => $reviews->lastPage(),
                'per_page' => $reviews->perPage(),
                'total' => $reviews->total(),
            ],
            'summary' => [
                'average_rating' => $studio->average_rating,
                'total_reviews' => $studio->total_reviews,
                'rating_distribution' => $this->getRatingDistribution($studio->id),
            ],
        ]);
    }

    /**
     * Create a review (after completed booking)
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'booking_id' => 'required|exists:bookings,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'is_anonymous' => 'nullable|boolean',
        ]);

        $user = $request->user();
        $booking = Booking::where('id', $request->booking_id)
            ->where('user_id', $user->id)
            ->first();

        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak ditemukan',
            ], 404);
        }

        // Check if booking is completed
        if ($booking->status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya booking yang sudah selesai yang bisa direview',
            ], 422);
        }

        // Check if already reviewed
        $existingReview = Review::where('user_id', $user->id)
            ->where('booking_id', $booking->id)
            ->first();

        if ($existingReview) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memberikan review untuk booking ini',
            ], 409);
        }

        // Apply profanity filter to comment
        $filteredComment = $request->comment ? ProfanityFilter::censor($request->comment) : null;

        $review = Review::create([
            'user_id' => $user->id,
            'studio_id' => $booking->studio_id,
            'booking_id' => $booking->id,
            'rating' => $request->rating,
            'comment' => $filteredComment,
            'is_anonymous' => $request->boolean('is_anonymous'),
        ]);

        // Update studio rating
        $this->updateStudioRating($booking->studio_id);

        return response()->json([
            'success' => true,
            'message' => 'Review berhasil dikirim',
            'data' => [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => ProfanityFilter::censor($review->comment ?? ''),
                'created_at' => $review->created_at->toISOString(),
            ],
        ], 201);
    }

    /**
     * Get user's reviews
     */
    public function userReviews(Request $request): JsonResponse
    {
        $reviews = Review::where('user_id', $request->user()->id)
            ->with('studio:id,name,slug')
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $reviews->map(function ($review) {
                return [
                    'id' => $review->id,
                    'studio' => [
                        'id' => $review->studio->id,
                        'name' => $review->studio->name,
                        'slug' => $review->studio->slug,
                    ],
                    'rating' => $review->rating,
                    'comment' => ProfanityFilter::censor($review->comment ?? ''),
                    'created_at' => $review->created_at->toISOString(),
                ];
            }),
            'meta' => [
                'current_page' => $reviews->currentPage(),
                'last_page' => $reviews->lastPage(),
                'per_page' => $reviews->perPage(),
                'total' => $reviews->total(),
            ],
        ]);
    }

    /**
     * Delete a review
     */
    public function destroy(Request $request, Review $review): JsonResponse
    {
        if ($review->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk menghapus review ini',
            ], 403);
        }

        $studioId = $review->studio_id;
        $review->delete();

        // Update studio rating
        $this->updateStudioRating($studioId);

        return response()->json([
            'success' => true,
            'message' => 'Review berhasil dihapus',
        ]);
    }

    /**
     * Update studio average rating using DB aggregate (no N+1)
     */
    private function updateStudioRating(int $studioId): void
    {
        $stats = Review::where('studio_id', $studioId)
            ->selectRaw('AVG(rating) as avg_rating, COUNT(*) as total')
            ->first();

        Studio::where('id', $studioId)->update([
            'average_rating' => round($stats->avg_rating ?? 0, 1),
            'total_reviews' => $stats->total ?? 0,
        ]);
    }

    /**
     * Get rating distribution
     */
    private function getRatingDistribution(int $studioId): array
    {
        $distribution = Review::where('studio_id', $studioId)
            ->selectRaw('rating, COUNT(*) as count')
            ->groupBy('rating')
            ->pluck('count', 'rating')
            ->toArray();

        // Ensure all ratings 1-5 are present
        $result = [];
        for ($i = 1; $i <= 5; $i++) {
            $result[$i] = $distribution[$i] ?? 0;
        }

        return $result;
    }

    /**
     * Add images to review
     */
    public function addImages(Request $request, int $reviewId): JsonResponse
    {
        $user = $request->user();
        
        $review = Review::findOrFail($reviewId);
        
        // Check ownership
        if ($review->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke review ini',
            ], 403);
        }

        $request->validate([
            'images' => 'required|array|max:5',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:5120',
            'captions' => 'nullable|array',
            'captions.*' => 'nullable|string|max:255',
        ]);

        try {
            $photoService = new PhotoReviewService();
            $images = $photoService->addImages(
                $reviewId,
                $request->file('images'),
                $request->captions
            );

            return response()->json([
                'success' => true,
                'message' => count($images) . ' gambar berhasil ditambahkan',
                'data' => $images,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Remove image from review
     */
    public function removeImage(Request $request, int $imageId): JsonResponse
    {
        $user = $request->user();
        
        $image = \App\Models\ReviewImage::findOrFail($imageId);
        $review = Review::findOrFail($image->review_id);
        
        // Check ownership
        if ($review->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke gambar ini',
            ], 403);
        }

        try {
            $photoService = new PhotoReviewService();
            $photoService->removeImage($imageId);

            return response()->json([
                'success' => true,
                'message' => 'Gambar berhasil dihapus',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}
