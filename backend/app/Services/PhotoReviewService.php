<?php

namespace App\Services;

use App\Models\Review;
use App\Models\ReviewImage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class PhotoReviewService
{
    /**
     * Add images to a review
     */
    public function addImages(int $reviewId, array $images, ?array $captions = null): array
    {
        $review = Review::findOrFail($reviewId);
        $addedImages = [];

        foreach ($images as $index => $image) {
            if ($image instanceof UploadedFile) {
                $path = $image->store('reviews', 'public');
                $imageUrl = Storage::disk('public')->url($path);
            } else {
                $imageUrl = $image;
            }

            $caption = $captions[$index] ?? null;

            $reviewImage = ReviewImage::create([
                'review_id' => $reviewId,
                'image_url' => $imageUrl,
                'caption' => $caption,
                'sort_order' => $index,
            ]);

            $addedImages[] = $reviewImage;
        }

        return $addedImages;
    }

    /**
     * Remove image from review
     */
    public function removeImage(int $imageId): bool
    {
        $image = ReviewImage::findOrFail($imageId);
        
        // Delete file from storage
        if ($image->image_url) {
            $path = str_replace(Storage::disk('public')->url('/'), '', $image->image_url);
            Storage::disk('public')->delete($path);
        }

        return $image->delete();
    }

    /**
     * Update image caption
     */
    public function updateImage(int $imageId, ?string $caption): ReviewImage
    {
        $image = ReviewImage::findOrFail($imageId);
        $image->update(['caption' => $caption]);
        return $image;
    }

    /**
     * Reorder images
     */
    public function reorderImages(int $reviewId, array $imageIds): bool
    {
        foreach ($imageIds as $index => $imageId) {
            ReviewImage::where('id', $imageId)
                ->where('review_id', $reviewId)
                ->update(['sort_order' => $index]);
        }

        return true;
    }

    /**
     * Get review with images
     */
    public function getReviewWithImages(int $reviewId): Review
    {
        return Review::with(['images', 'user:id,name,avatar', 'studio:id,name,slug'])
            ->findOrFail($reviewId);
    }

    /**
     * Get studio reviews with images
     */
    public function getStudioReviews(int $studioId, int $page = 1, int $limit = 15): array
    {
        $reviews = Review::where('studio_id', $studioId)
            ->where('is_approved', true)
            ->with(['images', 'user:id,name,avatar'])
            ->orderBy('created_at', 'desc')
            ->paginate($limit, ['*'], 'page', $page);

        return [
            'reviews' => $reviews->items(),
            'meta' => [
                'current_page' => $reviews->currentPage(),
                'last_page' => $reviews->lastPage(),
                'per_page' => $reviews->perPage(),
                'total' => $reviews->total(),
            ],
        ];
    }
}
