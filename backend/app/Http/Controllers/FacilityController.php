<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreFacilityRequest;
use App\Http\Resources\FacilityResource;
use App\Models\Facility;
use App\Models\Studio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class FacilityController extends Controller
{
    /**
     * List facilities for an owner's studio (owner only, includes inactive)
     */
    public function index(Request $request, int $studioId)
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $facilities = $studio->facilities()
            ->orderBy('sort_order')
            ->get();

        return $this->successResponse(
            FacilityResource::collection($facilities),
            'Facilities retrieved successfully'
        );
    }

    /**
     * Store new facility (owner only)
     */
    public function store(StoreFacilityRequest $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $data = $request->validated();
        $data['studio_id'] = $studio->id;
        $data['image'] = $this->storeImage($request->file('image'));

        $facility = Facility::create($data);

        return $this->successResponse(
            new FacilityResource($facility),
            'Fasilitas berhasil ditambahkan',
            201
        );
    }

    /**
     * Update facility (owner only)
     */
    public function update(StoreFacilityRequest $request, int $studioId, int $facilityId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $facility = $studio->facilities()->findOrFail($facilityId);

        $data = $request->validated();

        // Replace image if a new one is uploaded
        if ($request->hasFile('image')) {
            $this->deleteImage($facility->image);
            $data['image'] = $this->storeImage($request->file('image'));
        }

        $facility->update($data);

        return $this->successResponse(
            new FacilityResource($facility->fresh()),
            'Fasilitas berhasil diperbarui'
        );
    }

    /**
     * Delete facility (owner only)
     */
    public function destroy(Request $request, int $studioId, int $facilityId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $facility = $studio->facilities()->findOrFail($facilityId);
        $this->deleteImage($facility->image);
        $facility->delete();

        return $this->successResponse(null, 'Fasilitas berhasil dihapus');
    }

    /**
     * Store uploaded image to public disk and return its URL
     */
    private function storeImage(?UploadedFile $file): ?string
    {
        if (!$file) {
            return null;
        }

        $path = $file->store('facilities', 'public');

        return Storage::disk('public')->url($path);
    }

    /**
     * Delete an image file from public disk (safe for external URLs)
     */
    private function deleteImage(?string $url): void
    {
        if (!$url) {
            return;
        }

        $path = str_replace(Storage::disk('public')->url('/'), '', $url);
        Storage::disk('public')->delete($path);
    }
}
