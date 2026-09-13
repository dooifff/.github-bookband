<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Studio;
use App\Models\Payment;
use App\Services\ProfanityFilter;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class OwnerDashboardController extends Controller
{
    /**
     * Get owner dashboard statistics
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        // Get date range from request (default: last 30 days)
        $startDate = $request->input('start_date', now()->subDays(30)->toDateString());
        $endDate = $request->input('end_date', now()->toDateString());

        // Total studios
        $studioStats = Studio::whereIn('id', $studioIds)
            ->selectRaw('COUNT(*) as total, SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active')
            ->first();
        $totalStudios = $studioStats->total;
        $activeStudios = $studioStats->active;

        // Bookings statistics - batch with single query
        $bookingCounts = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');
        $totalBookings = $bookingCounts->sum();
        $pendingBookings = $bookingCounts->get('pending', 0);
        $confirmedBookings = $bookingCounts->get('confirmed', 0);
        $completedBookings = $bookingCounts->get('completed', 0);
        $cancelledBookings = $bookingCounts->get('cancelled', 0);

        // Revenue statistics - single query for both sum and avg
        $revenueStats = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw('SUM(amount) as total_revenue, AVG(amount) as avg_booking')
        ->first();

        $totalRevenue = $revenueStats->total_revenue ?? 0;
        $avgBookingValue = $revenueStats->avg_booking ?? 0;

        // Today's bookings
        $todayBookings = Booking::whereIn('studio_id', $studioIds)
            ->where('date', now()->toDateString())
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->with(['user:id,name', 'room:id,name'])
            ->get();

        // Upcoming bookings (next 7 days)
        $upcomingBookings = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [now()->toDateString(), now()->addDays(7)->toDateString()])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->with(['user:id,name', 'room:id,name', 'studio:id,name'])
            ->orderBy('date')
            ->orderBy('start_time')
            ->limit(10)
            ->get();

        // Recent reviews
        $recentReviews = \App\Models\Review::whereIn('studio_id', $studioIds)
            ->with(['user:id,name', 'studio:id,name'])
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        // Occupancy rate (simplified calculation)
        $occupancyRate = $this->calculateOccupancyRate($studioIds, $startDate, $endDate);

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_studios' => $totalStudios,
                    'active_studios' => $activeStudios,
                    'total_bookings' => $totalBookings,
                    'total_revenue' => $totalRevenue,
                    'avg_booking_value' => round($avgBookingValue ?? 0),
                    'occupancy_rate' => round($occupancyRate, 1),
                ],
                'bookings' => [
                    'pending' => $pendingBookings,
                    'confirmed' => $confirmedBookings,
                    'completed' => $completedBookings,
                    'cancelled' => $cancelledBookings,
                ],
                'today_bookings' => $todayBookings->map(function ($booking) {
                    return [
                        'id' => $booking->id,
                        'booking_code' => $booking->booking_code,
                        'user' => $booking->user->name,
                        'room' => $booking->room->name,
                        'time' => $booking->start_time . ' - ' . $booking->end_time,
                        'amount' => $booking->total,
                        'status' => $booking->status,
                    ];
                }),
                'upcoming_bookings' => $upcomingBookings->map(function ($booking) {
                    return [
                        'id' => $booking->id,
                        'booking_code' => $booking->booking_code,
                        'date' => $booking->date,
                        'user' => $booking->user->name,
                        'studio' => $booking->studio->name,
                        'room' => $booking->room->name,
                        'time' => $booking->start_time . ' - ' . $booking->end_time,
                        'amount' => $booking->total,
                        'status' => $booking->status,
                    ];
                }),
                'recent_reviews' => $recentReviews->map(function ($review) {
                    return [
                        'id' => $review->id,
                        'user' => $review->user->name,
                        'studio' => $review->studio->name,
                        'rating' => $review->rating,
                        'comment' => ProfanityFilter::censor($review->comment ?? ''),
                        'created_at' => $review->created_at->toISOString(),
                    ];
                }),
                'period' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                ],
            ],
        ]);
    }

    /**
     * Calculate occupancy rate
     */
    private function calculateOccupancyRate($studioIds, string $startDate, string $endDate): float
    {
        // Get total available hours for all rooms in the period
        $totalRooms = \App\Models\StudioRoom::whereIn('studio_id', $studioIds)
            ->where('is_active', true)
            ->count();

        $days = Carbon::parse($startDate)->diffInDays(Carbon::parse($endDate)) + 1;
        $totalAvailableHours = $totalRooms * $days * 12; // Assuming 12 hours operation per day

        // Get total booked hours
        $bookedHours = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->sum('duration_hours');

        if ($totalAvailableHours == 0) {
            return 0;
        }

        return ($bookedHours / $totalAvailableHours) * 100;
    }

    /**
     * Get quick stats for today
     */
    public function todayStats(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        $todayBookings = Booking::whereIn('studio_id', $studioIds)
            ->where('date', now()->toDateString())
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->count();

        $todayRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds)
                  ->where('date', now()->toDateString());
        })
        ->where('status', 'paid')
        ->sum('amount');

        $pendingPayments = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds)
                  ->where('date', now()->toDateString());
        })
        ->where('status', 'pending')
        ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'today_bookings' => $todayBookings,
                'today_revenue' => $todayRevenue,
                'pending_payments' => $pendingPayments,
                'date' => now()->toDateString(),
            ],
        ]);
    }
}
