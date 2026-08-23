<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Services\BookingService;
use App\Http\Requests\StoreBookingRequest;
use App\Http\Resources\BookingResource;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BookingController extends Controller
{
    public function __construct(
        private BookingService $bookingService
    ) {}

    /**
     * Get user's bookings
     */
    public function index(Request $request): JsonResponse
    {
        $status = $request->query('status');
        
        $bookings = $this->bookingService->getUserBookings($request->user(), $status);

        return response()->json([
            'success' => true,
            'data' => BookingResource::collection($bookings),
            'meta' => [
                'current_page' => $bookings->currentPage(),
                'last_page' => $bookings->lastPage(),
                'per_page' => $bookings->perPage(),
                'total' => $bookings->total(),
            ],
        ]);
    }

    /**
     * Create a new booking
     */
    public function store(StoreBookingRequest $request): JsonResponse
    {
        try {
            $booking = $this->bookingService->createBooking(
                $request->validated(),
                $request->user()
            );

            return response()->json([
                'success' => true,
                'message' => 'Booking berhasil dibuat',
                'data' => new BookingResource($booking),
            ], 201);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Get booking detail
     */
    public function show(Booking $booking): JsonResponse
    {
        // Check if user has access to this booking
        $user = request()->user();
        
        if ($booking->user_id !== $user->id && 
            !in_array($user->role, ['admin', 'super_admin']) &&
            !$this->isOwnerOfStudio($user, $booking->studio_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke booking ini',
            ], 403);
        }

        $booking->load(['studio', 'room', 'payment', 'band']);

        return response()->json([
            'success' => true,
            'data' => new BookingResource($booking),
        ]);
    }

    /**
     * Cancel a booking
     */
    public function cancel(Request $request, Booking $booking): JsonResponse
    {
        try {
            $booking = $this->bookingService->cancelBooking(
                $booking,
                $request->user(),
                $request->input('reason')
            );

            return response()->json([
                'success' => true,
                'message' => 'Booking berhasil dibatalkan',
                'data' => new BookingResource($booking),
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Get booking by code
     */
    public function showByCode(string $code): JsonResponse
    {
        $booking = Booking::where('booking_code', $code)
            ->with(['studio', 'room', 'payment', 'band'])
            ->first();

        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak ditemukan',
            ], 404);
        }

        $user = request()->user();
        
        if ($booking->user_id !== $user->id && 
            !in_array($user->role, ['admin', 'super_admin']) &&
            !$this->isOwnerOfStudio($user, $booking->studio_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke booking ini',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => new BookingResource($booking),
        ]);
    }

    /**
     * Get owner's studio bookings
     */
    public function ownerBookings(Request $request): JsonResponse
    {
        $status = $request->query('status');
        
        $bookings = $this->bookingService->getOwnerBookings($request->user(), $status);

        return response()->json([
            'success' => true,
            'data' => BookingResource::collection($bookings),
            'meta' => [
                'current_page' => $bookings->currentPage(),
                'last_page' => $bookings->lastPage(),
                'per_page' => $bookings->perPage(),
                'total' => $bookings->total(),
            ],
        ]);
    }

    /**
     * Confirm a booking (owner/admin only)
     */
    public function confirm(Booking $booking): JsonResponse
    {
        $user = request()->user();
        
        if (!in_array($user->role, ['admin', 'super_admin']) &&
            !$this->isOwnerOfStudio($user, $booking->studio_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk mengkonfirmasi booking ini',
            ], 403);
        }

        try {
            $booking = $this->bookingService->confirmBooking($booking);

            return response()->json([
                'success' => true,
                'message' => 'Booking berhasil dikonfirmasi',
                'data' => new BookingResource($booking),
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Complete a booking (owner/admin only)
     */
    public function complete(Booking $booking): JsonResponse
    {
        $user = request()->user();
        
        if (!in_array($user->role, ['admin', 'super_admin']) &&
            !$this->isOwnerOfStudio($user, $booking->studio_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk menyelesaikan booking ini',
            ], 403);
        }

        try {
            $booking = $this->bookingService->completeBooking($booking);

            return response()->json([
                'success' => true,
                'message' => 'Booking berhasil diselesaikan',
                'data' => new BookingResource($booking),
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Check if user is owner of the studio
     */
    private function isOwnerOfStudio($user, int $studioId): bool
    {
        return $user->ownedStudios()->where('id', $studioId)->exists();
    }

    /**
     * Export booking invoice as PDF
     */
    public function exportInvoice(Booking $booking)
    {
        $user = request()->user();
        
        // Check if user is the booking owner, studio owner, or admin
        if ($booking->user_id !== $user->id &&
            !$this->isOwnerOfStudio($user, $booking->studio_id) &&
            !in_array($user->role, ['admin', 'super_admin'])) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk mengunduh invoice ini',
            ], 403);
        }

        try {
            $pdfService = new \App\Services\PdfExportService();
            $pdf = $pdfService->exportInvoice($booking->id);
            
            $filename = 'invoice-' . $booking->booking_code . '.pdf';
            
            return $pdf->download($filename);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengunduh invoice: ' . $e->getMessage(),
            ], 500);
        }
    }
}
