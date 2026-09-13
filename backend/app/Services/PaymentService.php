<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;
use InvalidArgumentException;

class PaymentService
{
    public function __construct()
    {
        $this->configureMidtrans();
    }

    /**
     * Configure Midtrans settings
     */
    private function configureMidtrans(): void
    {
        $serverKey = config('payment.midtrans.server_key', '');
        $clientKey = config('payment.midtrans.client_key', '');

        \Midtrans\Config::$serverKey = $serverKey;
        \Midtrans\Config::$clientKey = $clientKey;
        \Midtrans\Config::$isProduction = config('payment.midtrans.is_production', false);
        \Midtrans\Config::$isSanitized = true;
        \Midtrans\Config::$is3ds = true;
        \Midtrans\Config::$curlOptions = [
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_SSL_VERIFYHOST => 0,
            CURLOPT_HTTPHEADER => [],
        ];
    }

    /**
     * Check if Midtrans is properly configured
     */
    private function isMidtransConfigured(): bool
    {
        $serverKey = config('payment.midtrans.server_key', '');
        return !empty($serverKey) && $serverKey !== '';
    }

    /**
     * Create a payment for a booking using Midtrans Snap
     *
     * @throws InvalidArgumentException
     */
    public function createPayment(Booking $booking, string $method, ?string $provider = null): Payment
    {
        // Validate booking status
        if (!in_array($booking->status, ['pending', 'awaiting_payment'])) {
            throw new InvalidArgumentException('Booking tidak dalam status yang valid untuk pembayaran');
        }

        // Check if payment already exists and is still active
        if ($booking->payment && in_array($booking->payment->status, ['pending'])) {
            // Return existing payment if still pending
            return $booking->payment;
        }

        return DB::transaction(function () use ($booking, $method) {
            // Load relationships
            $booking->load(['studio', 'room', 'user']);

            // Generate payment code
            $paymentCode = $this->generatePaymentCode();

            // Calculate amount from room price and duration to match Midtrans gross_amount
            $pricePerHour = (int) $booking->room->price_per_hour;
            $duration = max(1, (int) ceil($booking->duration_hours));
            $amount = $pricePerHour * $duration;

            // Create payment record
            $payment = Payment::create([
                'user_id' => $booking->user_id,
                'booking_id' => $booking->id,
                'payment_code' => $paymentCode,
                'amount' => $amount,
                'payment_method' => $method,
                'provider' => 'midtrans',
                'status' => 'pending',
                'expired_at' => now()->addHours(24),
            ]);

            // Update booking status
            $booking->update([
                'status' => 'awaiting_payment',
            ]);

            // Build Midtrans transaction payload
            $transactionData = $this->buildTransactionData($payment, $booking);

            // Check if Midtrans is configured
            if (!$this->isMidtransConfigured()) {
                Log::warning('Midtrans keys not configured, using sandbox mode', [
                    'payment_code' => $paymentCode,
                ]);

                // Sandbox mode: create fake success response for testing
                $payment->update([
                    'provider_payment_id' => 'sandbox_' . $paymentCode,
                    'payment_url' => config('app.url') . '/customer/bookings?payment=sandbox&code=' . $paymentCode,
                    'raw_response' => [
                        'token' => 'sandbox_' . $paymentCode,
                        'redirect_url' => config('app.url') . '/customer/bookings?payment=sandbox&code=' . $paymentCode,
                        'mode' => 'sandbox',
                    ],
                ]);
            } else {
                try {
                    Log::info('Midtrans Snap request', [
                        'payment_code' => $paymentCode,
                        'payload' => $transactionData,
                    ]);

                    // Get Snap token from Midtrans
                    $snapResponse = Snap::createTransaction($transactionData);

                    Log::info('Midtrans Snap response', [
                        'payment_code' => $paymentCode,
                        'response' => (array) $snapResponse,
                    ]);

                    $payment->update([
                        'provider_payment_id' => $snapResponse->token,
                        'payment_url' => $snapResponse->redirect_url,
                        'raw_response' => (array) $snapResponse,
                    ]);
                } catch (\Exception $e) {
                    Log::error('Midtrans Snap error', [
                        'payment_code' => $paymentCode,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString(),
                    ]);

                    $payment->update([
                        'status' => 'failed',
                        'raw_response' => ['error' => $e->getMessage()],
                    ]);

                    throw new InvalidArgumentException('Gagal membuat pembayaran Midtrans: ' . $e->getMessage());
                }
            }

            return $payment->fresh();
        });
    }

    /**
     * Build Midtrans transaction data
     */
    private function buildTransactionData(Payment $payment, Booking $booking): array
    {
        $orderId = $payment->payment_code;
        $pricePerHour = (int) $booking->room->price_per_hour;
        $duration = max(1, (int) ceil($booking->duration_hours));

        // gross_amount MUST equal sum of (price * quantity) in item_details
        $grossAmount = $pricePerHour * $duration;

        return [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $grossAmount,
            ],
            'item_details' => [[
                'id' => (string) $booking->room_id,
                'price' => $pricePerHour,
                'quantity' => $duration,
                'name' => substr("{$booking->room->name} - {$booking->date}", 0, 50),
            ]],
            'customer_details' => [
                'first_name' => $booking->user->name ?? 'Customer',
                'email' => $booking->user->email ?? '',
                'phone' => $booking->user->phone ?? '08123456789',
            ],
            'callbacks' => [
                'finish' => config('app.url') . '/customer/bookings',
            ],
        ];
    }

    /**
     * Handle Midtrans notification webhook
     *
     * @throws InvalidArgumentException
     */
    public function handleMidtransNotification(array $payload): Payment
    {
        $transactionId = $payload['transaction_id'] ?? '';
        $orderId = $payload['order_id'] ?? '';
        $statusCode = $payload['status_code'] ?? '';
        $grossAmount = $payload['gross_amount'] ?? '';
        $fraudStatus = $payload['fraud_status'] ?? '';
        $transactionStatus = $payload['transaction_status'] ?? '';

        // Find payment
        $payment = Payment::where('payment_code', $orderId)
            ->with('booking')
            ->first();

        if (!$payment) {
            throw new InvalidArgumentException("Payment not found for order: {$orderId}");
        }

        // Verify signature
        $signatureKey = hash('sha512',
            $orderId .
            $statusCode .
            $grossAmount .
            config('payment.midtrans.server_key', '')
        );

        if ($signatureKey !== ($payload['signature_key'] ?? '')) {
            Log::warning('Midtrans signature mismatch', ['order_id' => $orderId]);
            throw new InvalidArgumentException('Invalid signature');
        }

        // Map Midtrans status to our status
        $status = $this->mapMidtransStatus($transactionStatus, $fraudStatus);

        Log::info('Midtrans notification received', [
            'order_id' => $orderId,
            'transaction_status' => $transactionStatus,
            'fraud_status' => $fraudStatus,
            'mapped_status' => $status,
        ]);

        return DB::transaction(function () use ($payment, $status, $payload) {
            // Update payment
            $payment->update([
                'status' => $status,
                'provider_payment_id' => $payload['transaction_id'] ?? $payment->provider_payment_id,
                'payment_type' => $payload['payment_type'] ?? null,
                'raw_response' => $payload,
                'paid_at' => in_array($status, ['paid']) ? now() : $payment->paid_at,
            ]);

            // Update booking status
            $bookingStatus = match($status) {
                'paid' => 'paid',
                'failed' => 'failed',
                'expired' => 'expired',
                'cancelled' => 'cancelled',
                'refunded' => 'refunded',
                default => $payment->booking->status,
            };

            $payment->booking->update([
                'status' => $bookingStatus,
            ]);

            // Send notification to user
            $this->sendPaymentNotification($payment, $status);

            return $payment->fresh();
        });
    }

    /**
     * Map Midtrans transaction status to our internal status
     */
    private function mapMidtransStatus(string $transactionStatus, ?string $fraudStatus): string
    {
        // If fraud is challenge, treat as pending
        if ($fraudStatus === 'challenge') {
            return 'pending';
        }

        return match($transactionStatus) {
            'capture' => $fraudStatus === 'accept' ? 'paid' : 'pending',
            'settlement' => 'paid',
            'pending' => 'pending',
            'deny' => 'failed',
            'expire' => 'expired',
            'cancel' => 'cancelled',
            'refund' => 'refunded',
            'partial_refund' => 'refunded',
            default => 'pending',
        };
    }

    /**
     * Send notification to user about payment status
     */
    private function sendPaymentNotification(Payment $payment, string $status): void
    {
        try {
            $booking = $payment->booking;

            $title = match($status) {
                'paid' => 'Pembayaran Berhasil',
                'failed' => 'Pembayaran Gagal',
                'expired' => 'Pembayaran Kedaluwarsa',
                'cancelled' => 'Pembayaran Dibatalkan',
                default => null,
            };

            if (!$title) return;

            $body = match($status) {
                'paid' => "Pembayaran untuk booking {$booking->booking_code} telah berhasil. Total: {$payment->formatted_amount}",
                'failed' => "Pembayaran untuk booking {$booking->booking_code} gagal. Silakan coba lagi.",
                'expired' => "Pembayaran untuk booking {$booking->booking_code} telah kedaluwarsa.",
                'cancelled' => "Pembayaran untuk booking {$booking->booking_code} telah dibatalkan.",
                default => '',
            };

            \App\Models\Notification::create([
                'user_id' => $booking->user_id,
                'type' => 'payment',
                'title' => $title,
                'body' => $body,
                'data' => [
                    'booking_id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                    'payment_code' => $payment->payment_code,
                    'status' => $status,
                    'amount' => $payment->amount,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send payment notification', [
                'payment_id' => $payment->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Get payment status from Midtrans
     */
    public function checkPaymentStatus(Payment $payment): string
    {
        try {
            $status = Snap::getPaymentStatus($payment->payment_code);
            return $status->transaction_status ?? 'pending';
        } catch (\Exception $e) {
            Log::error('Failed to check Midtrans status', [
                'payment_code' => $payment->payment_code,
                'error' => $e->getMessage(),
            ]);
            return 'pending';
        }
    }

    /**
     * Generate unique payment code
     */
    private function generatePaymentCode(): string
    {
        $prefix = 'SB';
        $date = now()->format('ymd');
        $random = strtoupper(substr(uniqid(), -6));

        return "{$prefix}{$date}{$random}";
    }

    /**
     * Get user's payments
     */
    public function getUserPayments(User $user)
    {
        return Payment::whereHas('booking', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })
        ->with('booking')
        ->orderBy('created_at', 'desc')
        ->paginate(15);
    }

    /**
     * Get payment by booking
     */
    public function getPaymentByBooking(Booking $booking): ?Payment
    {
        return $booking->payment;
    }

    /**
     * Check if payment is expired
     */
    public function isPaymentExpired(Payment $payment): bool
    {
        return $payment->expired_at && $payment->expired_at->isPast() && $payment->status === 'pending';
    }

    /**
     * Expire old pending payments (run via scheduler)
     */
    public function expireOldPayments(): int
    {
        $expiredPayments = Payment::where('status', 'pending')
            ->where('expired_at', '<', now())
            ->get();

        foreach ($expiredPayments as $payment) {
            $payment->update(['status' => 'expired']);
            $payment->booking->update(['status' => 'expired']);
        }

        return $expiredPayments->count();
    }
}
