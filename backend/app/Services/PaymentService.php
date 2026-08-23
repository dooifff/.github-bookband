<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use InvalidArgumentException;

class PaymentService
{
    /**
     * Create a payment for a booking
     * 
     * Payment gateway abstraction - supports Midtrans and Xendit
     */
    public function createPayment(Booking $booking, string $method, ?string $provider = null): Payment
    {
        // Validate booking status
        if (!in_array($booking->status, ['pending', 'awaiting_payment'])) {
            throw new InvalidArgumentException('Booking tidak dalam status yang valid untuk pembayaran');
        }

        // Check if payment already exists
        if ($booking->payment && $booking->payment->status !== 'failed') {
            throw new InvalidArgumentException('Booking sudah memiliki pembayaran aktif');
        }

        // Default to midtrans if not specified
        $provider = $provider ?? config('payment.default_provider', 'midtrans');

        return DB::transaction(function () use ($booking, $method, $provider) {
            // Generate payment code
            $paymentCode = $this->generatePaymentCode();

            // Create payment record
            $payment = Payment::create([
                'booking_id' => $booking->id,
                'payment_code' => $paymentCode,
                'amount' => $booking->total,
                'method' => $method,
                'provider' => $provider,
                'status' => 'pending',
                'expires_at' => now()->addHours(24), // 24 hours to complete payment
            ]);

            // Update booking status
            $booking->update([
                'status' => 'awaiting_payment',
            ]);

            // Initialize payment with provider
            $providerResponse = $this->initializeProviderPayment($payment, $booking, $provider);

            if ($providerResponse['success']) {
                $payment->update([
                    'provider_reference' => $providerResponse['reference'] ?? null,
                    'provider_response' => $providerResponse,
                ]);
            }

            return $payment->fresh();
        });
    }

    /**
     * Initialize payment with the selected provider
     */
    private function initializeProviderPayment(Payment $payment, Booking $booking, string $provider): array
    {
        // This is where you would integrate with actual payment providers
        // For now, we'll return a mock response
        
        return match($provider) {
            'midtrans' => $this->initializeMidtrans($payment, $booking),
            'xendit' => $this->initializeXendit($payment, $booking),
            default => throw new InvalidArgumentException('Payment provider tidak didukung'),
        };
    }

    /**
     * Initialize Midtrans payment
     */
    private function initializeMidtrans(Payment $payment, Booking $booking): array
    {
        // Midtrans integration
        // In production, this would call Midtrans API
        $serverKey = config('payment.midtrans.server_key');
        $isProduction = config('payment.midtrans.is_production', false);
        
        $baseUrl = $isProduction 
            ? 'https://app.midtrans.com/snap/v1' 
            : 'https://app.sandbox.midtrans.com/snap/v1';

        // Create transaction
        $transactionData = [
            'transaction_details' => [
                'order_id' => $payment->payment_code,
                'gross_amount' => (int) $payment->amount,
            ],
            'customer_details' => [
                'first_name' => $booking->user->name,
                'email' => $booking->user->email,
                'phone' => $booking->user->phone,
            ],
            'item_details' => [
                [
                    'id' => $booking->room_id,
                    'price' => (int) $booking->room->price_per_hour,
                    'quantity' => (int) $booking->duration_hours,
                    'name' => "{$booking->room->name} - {$booking->date}",
                ],
            ],
            'callbacks' => [
                'finish' => config('app.url') . '/payment/finish',
            ],
        ];

        // In production, make actual API call:
        // $response = Http::withBasicAuth($serverKey, '')
        //     ->post("{$baseUrl}/transactions", $transactionData);
        
        // Mock response for development
        return [
            'success' => true,
            'reference' => 'MID-' . Str::random(10),
            'snap_token' => 'mock-snap-token-' . Str::random(20),
            'redirect_url' => config('app.url') . '/payment/mock',
        ];
    }

    /**
     * Initialize Xendit payment
     */
    private function initializeXendit(Payment $payment, Booking $booking): array
    {
        // Xendit integration
        $secretKey = config('payment.xendit.secret_key');
        
        // In production, this would call Xendit API
        $transactionData = [
            'external_id' => $payment->payment_code,
            'amount' => (int) $payment->amount,
            'description' => "StudioBook Booking - {$booking->room->name}",
            'invoice_duration' => 86400, // 24 hours
            'customer' => [
                'given_names' => $booking->user->name,
                'email' => $booking->user->email,
                'mobile_number' => $booking->user->phone,
            ],
            'success_redirect_url' => config('app.url') . '/payment/success',
            'failure_redirect_url' => config('app.url') . '/payment/failed',
        ];

        // In production, make actual API call:
        // $response = Http::withToken($secretKey)
        //     ->post('https://api.xendit.co/v2/invoices', $transactionData);
        
        // Mock response for development
        return [
            'success' => true,
            'reference' => 'XEN-' . Str::random(10),
            'invoice_id' => 'mock-invoice-' . Str::random(15),
            'invoice_url' => config('app.url') . '/payment/mock',
        ];
    }

    /**
     * Handle payment webhook from provider
     */
    public function handleWebhook(string $provider, array $payload): Payment
    {
        // Validate webhook signature
        if (!$this->validateWebhookSignature($provider, $payload)) {
            throw new InvalidArgumentException('Invalid webhook signature');
        }

        $paymentCode = $this->extractPaymentCode($provider, $payload);
        
        $payment = Payment::where('payment_code', $paymentCode)
            ->with('booking')
            ->first();

        if (!$payment) {
            throw new InvalidArgumentException('Payment tidak ditemukan');
        }

        $status = $this->mapProviderStatus($provider, $payload['transaction_status'] ?? $payload['status'] ?? '');

        return DB::transaction(function () use ($payment, $status, $payload) {
            // Update payment status
            $payment->update([
                'status' => $status,
                'provider_response' => $payload,
                'paid_at' => $status === 'paid' ? now() : null,
            ]);

            // Update booking status based on payment status
            $bookingStatus = match($status) {
                'paid' => 'paid',
                'failed' => 'failed',
                'expired' => 'expired',
                'refunded' => 'refunded',
                default => $payment->booking->status,
            };

            $payment->booking->update([
                'status' => $bookingStatus,
            ]);

            return $payment->fresh();
        });
    }

    /**
     * Validate webhook signature
     */
    private function validateWebhookSignature(string $provider, array $payload): bool
    {
        // Implement actual signature validation for each provider
        return true; // Mock validation for development
    }

    /**
     * Extract payment code from webhook payload
     */
    private function extractPaymentCode(string $provider, array $payload): string
    {
        return match($provider) {
            'midtrans' => $payload['order_id'] ?? '',
            'xendit' => $payload['external_id'] ?? '',
            default => '',
        };
    }

    /**
     * Map provider status to our status
     */
    private function mapProviderStatus(string $provider, string $status): string
    {
        return match($provider) {
            'midtrans' => match($status) {
                'capture' => 'paid',
                'settlement' => 'paid',
                'pending' => 'pending',
                'deny' => 'failed',
                'expire' => 'expired',
                'cancel' => 'cancelled',
                'refund' => 'refunded',
                default => 'pending',
            },
            'xendit' => match($status) {
                'PAID' => 'paid',
                'EXPIRED' => 'expired',
                'PENDING' => 'pending',
                default => 'pending',
            },
            default => 'pending',
        };
    }

    /**
     * Generate unique payment code
     */
    private function generatePaymentCode(): string
    {
        $prefix = 'PAY';
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
        return $payment->expires_at && $payment->expires_at->isPast() && $payment->status === 'pending';
    }

    /**
     * Expire old pending payments
     * Should be run via Laravel Scheduler
     */
    public function expireOldPayments(): int
    {
        $expiredCount = Payment::where('status', 'pending')
            ->where('expires_at', '<', now())
            ->update(['status' => 'expired']);

        // Also update associated bookings
        Payment::where('status', 'expired')
            ->whereNotNull('booking_id')
            ->each(function ($payment) {
                $payment->booking->update(['status' => 'expired']);
            });

        return $expiredCount;
    }
}
