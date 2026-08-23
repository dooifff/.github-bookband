<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Services\PaymentService;
use App\Http\Resources\PaymentResource;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

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
            'method' => 'required|in:bank_transfer,credit_card,debit_card,ewallet',
            'provider' => 'nullable|in:midtrans,xendit',
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
                $request->provider
            );

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran berhasil dibuat',
                'data' => new PaymentResource($payment),
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
    public function show(string $paymentCode): JsonResponse
    {
        $payment = \App\Models\Payment::where('payment_code', $paymentCode)
            ->with('booking')
            ->first();

        if (!$payment) {
            return response()->json([
                'success' => false,
                'message' => 'Pembayaran tidak ditemukan',
            ], 404);
        }

        // Check authorization
        $user = $request()->user();
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
     * Handle payment webhook from provider
     */
    public function webhook(Request $request, string $provider): JsonResponse
    {
        try {
            $payment = $this->paymentService->handleWebhook(
                $provider,
                $request->all()
            );

            return response()->json([
                'success' => true,
                'message' => 'Webhook processed',
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
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
        $payment = \App\Models\Payment::where('payment_code', $paymentCode)
            ->first();

        if (!$payment) {
            return response()->json([
                'success' => false,
                'message' => 'Pembayaran tidak ditemukan',
            ], 404);
        }

        // Check if payment is expired
        if ($this->paymentService->isPaymentExpired($payment)) {
            // Update status to expired
            $payment->update(['status' => 'expired']);
            $payment->booking->update(['status' => 'expired']);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'payment_code' => $payment->payment_code,
                'status' => $payment->status,
                'amount' => $payment->amount,
                'paid_at' => $payment->paid_at?->toISOString(),
                'expires_at' => $payment->expires_at?->toISOString(),
            ],
        ]);
    }
}
