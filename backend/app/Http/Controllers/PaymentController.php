<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Payment;
use App\Services\PaymentService;
use App\Http\Resources\PaymentResource;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function __construct(
        private PaymentService $paymentService
    ) {}

    /**
     * Create a payment for a booking
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'booking_id' => 'required|exists:bookings,id',
            'method' => 'required|in:bank_transfer,credit_card,debit_card,ewallet,gopay,shopeepay,qris',
        ]);

        $booking = Booking::where('id', $request->booking_id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak ditemukan',
            ], 404);
        }

        try {
            $payment = $this->paymentService->createPayment(
                $booking,
                $request->method,
                'midtrans'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran berhasil dibuat',
                'data' => [
                    'payment_code' => $payment->payment_code,
                    'amount' => $payment->amount,
                    'status' => $payment->status,
                    'payment_url' => $payment->payment_url,
                    'snap_token' => $payment->provider_reference,
                    'expired_at' => $payment->expired_at?->toISOString(),
                ],
            ], 201);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Get payment details
     */
    public function show(Request $request, string $paymentCode): JsonResponse
    {
        $payment = Payment::where('payment_code', $paymentCode)
            ->with('booking')
            ->first();

        if (!$payment) {
            return response()->json([
                'success' => false,
                'message' => 'Pembayaran tidak ditemukan',
            ], 404);
        }

        // Check authorization
        $user = $request->user();
        if ($payment->booking->user_id !== $user->id &&
            !in_array($user->role, ['admin', 'super_admin'])) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke pembayaran ini',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => new PaymentResource($payment),
        ]);
    }

    /**
     * Handle Midtrans notification webhook
     */
    public function midtransNotification(Request $request): JsonResponse
    {
        try {
            Log::info('Midtrans notification received', $request->all());

            $payment = $this->paymentService->handleMidtransNotification($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Notification processed',
            ]);
        } catch (\InvalidArgumentException $e) {
            Log::error('Midtrans notification error', [
                'error' => $e->getMessage(),
                'payload' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Midtrans notification unexpected error', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Handle payment webhook (legacy - for backward compatibility)
     */
    public function webhook(Request $request, string $provider): JsonResponse
    {
        if ($provider === 'midtrans') {
            return $this->midtransNotification($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'Unsupported provider',
        ], 400);
    }

    /**
     * Get user's payment history
     */
    public function history(Request $request): JsonResponse
    {
        $payments = $this->paymentService->getUserPayments($request->user());

        return response()->json([
            'success' => true,
            'data' => PaymentResource::collection($payments),
            'meta' => [
                'current_page' => $payments->currentPage(),
                'last_page' => $payments->lastPage(),
                'per_page' => $payments->perPage(),
                'total' => $payments->total(),
            ],
        ]);
    }

    /**
     * Get payment status
     */
    public function status(Request $request, string $paymentCode): JsonResponse
    {
        $payment = Payment::where('payment_code', $paymentCode)
            ->first();

        if (!$payment) {
            return response()->json([
                'success' => false,
                'message' => 'Pembayaran tidak ditemukan',
            ], 404);
        }

        // Check if payment is expired
        if ($this->paymentService->isPaymentExpired($payment)) {
            $payment->update(['status' => 'expired']);
            $payment->booking->update(['status' => 'expired']);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'payment_code' => $payment->payment_code,
                'status' => $payment->status,
                'amount' => $payment->amount,
                'payment_url' => $payment->payment_url,
                'paid_at' => $payment->paid_at?->toISOString(),
                'expired_at' => $payment->expired_at?->toISOString(),
            ],
        ]);
    }
}
