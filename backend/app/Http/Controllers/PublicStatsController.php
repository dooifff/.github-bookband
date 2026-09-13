<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Review;
use App\Models\Studio;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class PublicStatsController extends Controller
{
    /**
     * Get platform statistics for the landing page (real data from DB)
     */
    public function index(): JsonResponse
    {
        $totalStudios = Studio::where('is_active', true)->count();
        $totalBookings = Booking::where('status', '!=', 'cancelled')->count();
        $totalCities = Studio::where('is_active', true)->distinct()->count('city');
        $totalCustomers = User::where('role', 'customer')->count();
        $averageRating = Review::avg('rating');

        return response()->json([
            'success' => true,
            'data' => [
                'total_studios' => $totalStudios,
                'total_bookings' => $totalBookings,
                'total_cities' => $totalCities,
                'total_customers' => $totalCustomers,
                'average_rating' => $averageRating ? round((float) $averageRating, 1) : 0,
            ],
        ]);
    }
}