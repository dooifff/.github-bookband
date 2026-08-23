<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Studio;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class AdminDashboardController extends Controller
{
    /**
     * Get admin dashboard statistics
     */
    public function index(Request $request): JsonResponse
    {
        // Date range
        $period = $request->input('period', '30');
        $startDate = now()->subDays($period);
        $endDate = now();

        // User statistics - batch with single query
        $userCounts = User::selectRaw('role, COUNT(*) as count')
            ->groupBy('role')
            ->pluck('count', 'role');
        $totalUsers = $userCounts->sum();
        $newUsers = User::where('created_at', '>=', $startDate)->count();
        $customers = $userCounts->get('customer', 0);
        $owners = $userCounts->get('owner', 0);
        $admins = ($userCounts->get('admin', 0) ?? 0) + ($userCounts->get('super_admin', 0) ?? 0);

        // Studio statistics - batch with single query
        $studioStats = Studio::selectRaw('SUM(CASE WHEN is_verified = 0 THEN 1 ELSE 0 END) as pending_verification, SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active_count, SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactive_count, COUNT(*) as total')
            ->first();
        $totalStudios = $studioStats->total;
        $pendingVerification = $studioStats->pending_verification;
        $activeStudios = $studioStats->active_count;
        $inactiveStudios = $studioStats->inactive_count;

        // Booking statistics - batch with single query
        $bookingCounts = Booking::whereBetween('date', [$startDate, $endDate])
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');
        $totalBookings = $bookingCounts->sum();
        $pendingBookings = $bookingCounts->get('pending', 0);
        $completedBookings = $bookingCounts->get('completed', 0);
        $cancelledBookings = $bookingCounts->get('cancelled', 0);

        // Payment statistics
        $totalRevenue = Payment::where('status', 'paid')
            ->whereBetween('paid_at', [$startDate, $endDate])->sum('amount');
        $pendingPayments = Payment::where('status', 'pending')
            ->whereBetween('created_at', [$startDate, $endDate])->count();
        $failedPayments = Payment::where('status', 'failed')
            ->whereBetween('created_at', [$startDate, $endDate])->count();

        // Review statistics
        $totalReviews = Review::whereBetween('created_at', [$startDate, $endDate])->count();
        $avgRating = Review::whereBetween('created_at', [$startDate, $endDate])->avg('rating');

        // Recent activities
        $recentUsers = User::orderBy('created_at', 'desc')->limit(5)->get();
        $recentBookings = Booking::with(['user:id,name', 'studio:id,name'])
            ->orderBy('created_at', 'desc')->limit(5)->get();
        $recentStudios = Studio::with('owner:id,name')
            ->orderBy('created_at', 'desc')->limit(5)->get();

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_users' => $totalUsers,
                    'new_users' => $newUsers,
                    'total_studios' => $totalStudios,
                    'total_bookings' => $totalBookings,
                    'total_revenue' => $totalRevenue,
                    'total_reviews' => $totalReviews,
                ],
                'users' => [
                    'customers' => $customers,
                    'owners' => $owners,
                    'admins' => $admins,
                ],
                'studios' => [
                    'active' => $activeStudios,
                    'inactive' => $inactiveStudios,
                    'pending_verification' => $pendingVerification,
                ],
                'bookings' => [
                    'pending' => $pendingBookings,
                    'completed' => $completedBookings,
                    'cancelled' => $cancelledBookings,
                ],
                'payments' => [
                    'pending' => $pendingPayments,
                    'failed' => $failedPayments,
                ],
                'reviews' => [
                    'total' => $totalReviews,
                    'average_rating' => round($avgRating ?? 0, 1),
                ],
                'recent_activities' => [
                    'users' => $recentUsers->map(fn($u) => [
                        'id' => $u->id,
                        'name' => $u->name,
                        'email' => $u->email,
                        'role' => $u->role,
                        'created_at' => $u->created_at->toISOString(),
                    ]),
                    'bookings' => $recentBookings->map(fn($b) => [
                        'id' => $b->id,
                        'booking_code' => $b->booking_code,
                        'user' => $b->user->name,
                        'studio' => $b->studio->name,
                        'amount' => $b->total,
                        'status' => $b->status,
                        'created_at' => $b->created_at->toISOString(),
                    ]),
                    'studios' => $recentStudios->map(fn($s) => [
                        'id' => $s->id,
                        'name' => $s->name,
                        'owner' => $s->owner->name,
                        'is_verified' => $s->is_verified,
                        'created_at' => $s->created_at->toISOString(),
                    ]),
                ],
                'period' => [
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'days' => (int) $period,
                ],
            ],
        ]);
    }
}
