<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\Studio;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class OwnerAnalyticsController extends Controller
{
    /**
     * Get booking analytics
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        // Date range
        $period = $request->input('period', '30'); // days
        $startDate = now()->subDays($period);
        $endDate = now();

        // Bookings over time (daily)
        $bookingsOverTime = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw('date, COUNT(*) as count, SUM(total) as revenue')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Bookings by status
        $bookingsByStatus = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status');

        // Bookings by studio - eager load studio names to avoid N+1
        $studioMap = Studio::whereIn('id', $studioIds)->pluck('name', 'id');
        $bookingsByStudio = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw('studio_id, COUNT(*) as count, SUM(total) as revenue')
            ->groupBy('studio_id')
            ->get()
            ->map(function ($item) use ($studioMap) {
                return [
                    'studio_id' => $item->studio_id,
                    'studio_name' => $studioMap->get($item->studio_id, 'Unknown'),
                    'count' => $item->count,
                    'revenue' => $item->revenue,
                ];
            });

        // Peak hours analysis - use strftime for SQLite compatibility
        $dbDriver = DB::connection()->getConfig('driver');
        $hourExpr = $dbDriver === 'sqlite' ? "CAST(substr(start_time, 1, 2) AS INTEGER)" : 'HOUR(start_time)';
        $peakHours = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->selectRaw("{$hourExpr} as hour, COUNT(*) as count")
            ->groupBy('hour')
            ->orderBy('hour')
            ->get();

        // Popular rooms
        $popularRooms = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->with('room:id,name')
            ->selectRaw('room_id, COUNT(*) as count')
            ->groupBy('room_id')
            ->orderByDesc('count')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'room_id' => $item->room_id,
                    'room_name' => $item->room->name ?? 'Unknown',
                    'count' => $item->count,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'bookings_over_time' => $bookingsOverTime,
                'bookings_by_status' => $bookingsByStatus,
                'bookings_by_studio' => $bookingsByStudio,
                'peak_hours' => $peakHours,
                'popular_rooms' => $popularRooms,
                'period' => [
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'days' => (int) $period,
                ],
            ],
        ]);
    }

    /**
     * Get revenue analytics
     */
    public function revenue(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        $period = $request->input('period', '30');
        $startDate = now()->subDays($period);
        $endDate = now();

        // Revenue over time
        $revenueOverTime = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw('DATE(paid_at) as date, SUM(amount) as revenue, COUNT(*) as count')
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        // Revenue by studio - use DB aggregation instead of Collection
        $revenueByStudio = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studios', 'bookings.studio_id', '=', 'studios.id')
        ->selectRaw('bookings.studio_id, studios.name as studio_name, SUM(payments.amount) as total_revenue, COUNT(*) as transaction_count, AVG(payments.amount) as avg_transaction')
        ->groupBy('bookings.studio_id', 'studios.name')
        ->get();

        // Payment methods distribution
        $paymentMethods = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw('method, COUNT(*) as count, SUM(amount) as total')
        ->groupBy('method')
        ->get();

        // Monthly comparison
        $currentMonth = now()->startOfMonth();
        $previousMonth = now()->subMonth()->startOfMonth();

        $currentMonthRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [$currentMonth, now()])
        ->sum('amount');

        $previousMonthRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [$previousMonth, $currentMonth])
        ->sum('amount');

        $revenueGrowth = $previousMonthRevenue > 0 
            ? (($currentMonthRevenue - $previousMonthRevenue) / $previousMonthRevenue) * 100 
            : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'revenue_over_time' => $revenueOverTime,
                'revenue_by_studio' => $revenueByStudio,
                'payment_methods' => $paymentMethods,
                'monthly_comparison' => [
                    'current_month' => [
                        'revenue' => $currentMonthRevenue,
                        'label' => $currentMonth->format('M Y'),
                    ],
                    'previous_month' => [
                        'revenue' => $previousMonthRevenue,
                        'label' => $previousMonth->format('M Y'),
                    ],
                    'growth_percentage' => round($revenueGrowth, 1),
                ],
                'period' => [
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'days' => (int) $period,
                ],
            ],
        ]);
    }

    /**
     * Get occupancy analytics
     */
    public function occupancy(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        $period = $request->input('period', '30');
        $startDate = now()->subDays($period);
        $endDate = now();

        // Occupancy by day of week - SQLite compatible
        $dayOfWeekExpr = $dbDriver === 'sqlite' 
            ? "CAST(strftime('%w', date) AS INTEGER)" 
            : 'DAYOFWEEK(date)';
        $occupancyByDay = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->selectRaw("{$dayOfWeekExpr} as day, COUNT(*) as count, SUM(duration_hours * 60) as total_minutes")
            ->groupBy('day')
            ->get()
            ->map(function ($item) {
                $dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                return [
                    'day' => $dayNames[$item->day],
                    'day_number' => $item->day,
                    'bookings' => $item->count,
                    'total_hours' => round($item->total_minutes / 60, 1),
                ];
            });

        // Occupancy by studio - batch load to avoid N+1
        $studios = Studio::whereIn('id', $studioIds)->with('rooms:id,studio_id,is_active')->get();
        $studioRoomCounts = $studios->mapWithKeys(fn($s) => [$s->id => $s->rooms->where('is_active', true)->count()]);
        
        // Batch load all booked hours at once
        $bookedHoursByStudio = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->selectRaw('studio_id, SUM(duration_hours) as booked_hours')
            ->groupBy('studio_id')
            ->pluck('booked_hours', 'studio_id');

        $days = $startDate->diffInDays($endDate) + 1;
        $occupancyByStudio = [];
        foreach ($studioIds as $studioId) {
            $studio = $studios->firstWhere('id', $studioId);
            $totalRooms = $studioRoomCounts->get($studioId, 0);
            $bookedHours = $bookedHoursByStudio->get($studioId, 0);
            $totalAvailableHours = $totalRooms * $days * 12;
            $occupancyRate = $totalAvailableHours > 0 
                ? ($bookedHours / $totalAvailableHours) * 100 
                : 0;

            $occupancyByStudio[] = [
                'studio_id' => $studioId,
                'studio_name' => $studio->name ?? 'Unknown',
                'total_rooms' => $totalRooms,
                'booked_hours' => round($bookedHours, 1),
                'available_hours' => $totalAvailableHours,
                'occupancy_rate' => round($occupancyRate, 1),
            ];
        }

        // Average booking duration
        $avgDuration = Booking::whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->avg('duration_hours');

        return response()->json([
            'success' => true,
            'data' => [
                'occupancy_by_day' => $occupancyByDay,
                'occupancy_by_studio' => $occupancyByStudio,
                'average_booking_duration' => round($avgDuration ?? 0, 0),
                'period' => [
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'days' => (int) $period,
                ],
            ],
        ]);
    }
}
