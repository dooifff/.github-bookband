<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\PaymentService;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Booking;
use App\Models\Payment;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PaymentServiceTest extends TestCase
{
    use RefreshDatabase;

    protected $paymentService;
    protected $user;
    protected $studio;
    protected $room;

    protected function setUp(): void
    {
        parent::setUp();
        $this->paymentService = new PaymentService();
        $this->user = User::factory()->create(['role' => 'customer']);
        $this->studio = Studio::factory()->create([
            'is_active' => true,
            'is_verified' => true,
        ]);
        $this->room = StudioRoom::factory()->create([
            'studio_id' => $this->studio->id,
            'price_per_hour' => 50000,
        ]);
    }

    public function test_create_payment_record()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'duration_hours' => 2,
            'total' => 100000,
            'status' => 'pending',
        ]);

        $payment = $this->paymentService->createPayment($booking, 'bank_transfer', 'midtrans');

        $this->assertInstanceOf(Payment::class, $payment);
        $this->assertEquals($booking->id, $payment->booking_id);
        $this->assertEquals(100000, (float) $payment->amount); // 2 hours * 50000
        $this->assertEquals('pending', $payment->status);
        $this->assertEquals('midtrans', $payment->provider);
        $this->assertNotEmpty($payment->payment_code);
        $this->assertStringStartsWith('SB', $payment->payment_code);

        // Booking should move to awaiting_payment
        $this->assertEquals('awaiting_payment', $payment->booking->status);
    }

    public function test_create_payment_generates_unique_code()
    {
        $booking1 = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'duration_hours' => 1,
            'total' => 50000,
            'status' => 'pending',
        ]);

        $booking2 = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'duration_hours' => 1,
            'total' => 50000,
            'status' => 'pending',
        ]);

        $payment1 = $this->paymentService->createPayment($booking1, 'bank_transfer', 'midtrans');
        $payment2 = $this->paymentService->createPayment($booking2, 'ewallet', 'midtrans');

        $this->assertNotEquals($payment1->payment_code, $payment2->payment_code);
    }

    public function test_create_payment_returns_existing_pending_payment()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'duration_hours' => 1,
            'total' => 50000,
            'status' => 'awaiting_payment',
        ]);

        $first = $this->paymentService->createPayment($booking, 'bank_transfer', 'midtrans');
        // Fresh instance to mirror a new request in production (avoid relation caching)
        $second = $this->paymentService->createPayment($booking->fresh(), 'bank_transfer', 'midtrans');

        $this->assertEquals($first->id, $second->id);
        $this->assertEquals(1, Payment::where('booking_id', $booking->id)->count());
    }

    public function test_create_payment_fails_for_invalid_booking_status()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'duration_hours' => 1,
            'total' => 50000,
            'status' => 'completed',
        ]);

        $this->expectException(\InvalidArgumentException::class);

        $this->paymentService->createPayment($booking, 'bank_transfer', 'midtrans');
    }
}