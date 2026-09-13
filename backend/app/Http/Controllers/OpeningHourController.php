<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreOpeningHourRequest;
use App\Http\Resources\OpeningHourResource;
use App\Models\OpeningHour;
use App\Models\Studio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OpeningHourController extends Controller
{
    /**
     * List opening hours for a studio
     */
    public function index(Request $request, string $slug)
    {
        $studio = Studio::where('slug', $slug)->firstOrFail();

        $hours = $studio->openingHours()
            ->orderBy('day_of_week')
            ->get();

        return $this->successResponse(
            OpeningHourResource::collection($hours),
            'Opening hours retrieved successfully'
        );
    }

    /**
     * Update opening hours (owner only)
     */
    public function update(StoreOpeningHourRequest $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        // Check ownership
        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $hoursData = $request->validated()['hours'];

        foreach ($hoursData as $hourData) {
            OpeningHour::updateOrCreate(
                [
                    'studio_id' => $studioId,
                    'day_of_week' => $hourData['day_of_week'],
                ],
                [
                    'open_time' => $hourData['open_time'] ?? null,
                    'close_time' => $hourData['close_time'] ?? null,
                    'is_closed' => $hourData['is_closed'] ?? false,
                ]
            );
        }

        $hours = $studio->openingHours()->orderBy('day_of_week')->get();

        return $this->successResponse(
            OpeningHourResource::collection($hours),
            'Jam operasional berhasil diperbarui'
        );
    }

    /**
     * Check if studio is open at specific day and time
     */
    public function checkAvailability(Request $request, int $studioId)
    {
        $request->validate([
            'day_of_week' => 'required|integer|between:0,6',
            'time' => 'required|date_format:H:i',
        ]);

        $studio = Studio::findOrFail($studioId);

        $hour = $studio->openingHours()
            ->where('day_of_week', $request->day_of_week)
            ->first();

        if (!$hour || $hour->is_closed) {
            return $this->successResponse([
                'is_open' => false,
                'message' => 'Studio tutup pada hari ini',
            ]);
        }

        $isOpen = $request->time >= $hour->open_time && $request->time <= $hour->close_time;

        return $this->successResponse([
            'is_open' => $isOpen,
            'open_time' => $hour->open_time,
            'close_time' => $hour->close_time,
            'message' => $isOpen ? 'Studio buka' : 'Studio tutup pada jam ini',
        ]);
    }
}
