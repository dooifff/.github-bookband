<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminBookingController extends Controller
{
    /**
     * Get all bookings (admin view)
     */
    public function index(Request $request): JsonResponse
    {
        $query = Booking::with(['user:id,name,email', 'studio:id,name', 'room:id,name']);

        // Filter by status
        if ($request->has('status') && $request->status !== '') {
            $query->where('status', $request->status);
        }

        // Filter by date range
        if ($request->has('date_from')) {
            $query->where('date', '>=', $request->date_from);
        }
        if ($request->has('date_to')) {
            $query->where('date', '<=', $request->date_to);
        }

        // Filter by studio
        if ($request->has('studio_id')) {
            $query->where('studio_id', $request->studio_id);
        }

        // Filter by user
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        // Search by booking code
        if ($request->has('search') && $request->search !== '') {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('booking_code', 'like', "%{$search}%")
                  ->orWhereHas('user', function ($q2) use ($search) {
                      $q2->where('name', 'like', "%{$search}%")
                         ->orWhere('email', 'like', "%{$search}%");
                  });
            });
        }

        $bookings = $query->orderBy('date', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $bookings->items(),
            'meta' => [
                'current_page' => $bookings->currentPage(),
                'last_page' => $bookings->lastPage(),
                'per_page' => $bookings->perPage(),
                'total' => $bookings->total(),
            ],
        ]);
    }

    /**
     * Get booking detail (admin)
     */
    public function show(Booking $booking): JsonResponse
    {
        $booking->load(['user', 'studio', 'room', 'payment', 'review']);

        return response()->json([
            'success' => true,
            'data' => $booking,
        ]);
    }

    /**
     * Confirm a booking (admin)
     */
    public function confirm(Booking $booking): JsonResponse
    {
        if (!in_array($booking->status, ['pending', 'awaiting_payment'])) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak dapat dikonfirmasi pada status saat ini',
            ], 400);
        }

        $booking->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking berhasil dikonfirmasi',
            'data' => $booking->fresh()->load(['user:id,name,email', 'studio:id,name', 'room:id,name']),
        ]);
    }

    /**
     * Cancel a booking (admin)
     */
    public function cancel(Booking $booking, Request $request): JsonResponse
    {
        $reason = $request->get('reason', 'Dibatalkan oleh admin');

        if (!in_array($booking->status, ['pending', 'awaiting_payment', 'paid'])) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak dapat dibatalkan pada status saat ini',
            ], 400);
        }

        $booking->update([
            'status' => 'cancelled',
            'cancel_reason' => $reason,
            'cancelled_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking berhasil dibatalkan',
            'data' => $booking->fresh()->load(['user:id,name,email', 'studio:id,name', 'room:id,name']),
        ]);
    }

    /**
     * Get booking statistics (admin)
     */
    public function stats(): JsonResponse
    {
        $totalBookings = Booking::count();
        $pendingBookings = Booking::where('status', 'pending')->count();
        $confirmedBookings = Booking::where('status', 'confirmed')->count();
        $completedBookings = Booking::where('status', 'completed')->count();
        $cancelledBookings = Booking::where('status', 'cancelled')->count();
        $totalRevenue = Booking::where('status', 'completed')->sum('total');

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $totalBookings,
                'pending' => $pendingBookings,
                'confirmed' => $confirmedBookings,
                'completed' => $completedBookings,
                'cancelled' => $cancelledBookings,
                'total_revenue' => $totalRevenue,
            ],
        ]);
    }
}
