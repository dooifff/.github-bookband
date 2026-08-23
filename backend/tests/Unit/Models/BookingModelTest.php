<?php

namespace Tests\Unit\Models;

use Tests\TestCase;
use App\Models\Booking;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Payment;
use Illuminate\Foundation\Testing\RefreshDatabase;

class BookingModelTest extends TestCase
{
    use RefreshDatabase;

    protected $booking;

    protected function setUp(): void
    {
        parent::setUp();
        $this->booking = Booking::factory()->create();
    }

    public function test_booking_belongs_to_user()
    {
        $this->assertInstanceOf(User::class, $this->booking->user);
    }

    public function test_booking_belongs_to_studio()
    {
        $this->assertInstanceOf(Studio::class, $this->booking->studio);
    }

    public function test_booking_belongs_to_room()
    {
        $this->assertInstanceOf(StudioRoom::class, $this->booking->room);
    }

    public function test_booking_has_one_payment()
    {
        $payment = Payment::factory()->create([
            'booking_id' => $this->booking->id,
        ]);

        $this->assertTrue($this->booking->payment->is($payment));
    }

    public function test_booking_generates_unique_code()
    {
        $booking1 = Booking::factory()->create();
        $booking2 = Booking::factory()->create();

        $this->assertNotEquals($booking1->booking_code, $booking2->booking_code);
        $this->assertNotEmpty($booking1->booking_code);
    }

    public function test_booking_has_status()
    {
        $booking = Booking::factory()->create(['status' => 'confirmed']);

        $this->assertEquals('confirmed', $booking->status);
    }

    public function test_booking_can_be_cancelled()
    {
        $booking = Booking::factory()->create(['status' => 'confirmed']);

        $this->assertTrue($booking->canBeCancelled());
    }

    public function test_booking_cannot_be_cancelled_when_ongoing()
    {
        $booking = Booking::factory()->create(['status' => 'ongoing']);

        $this->assertFalse($booking->canBeCancelled());
    }

    public function test_booking_cannot_be_cancelled_when_completed()
    {
        $booking = Booking::factory()->create(['status' => 'completed']);

        $this->assertFalse($booking->canBeCancelled());
    }

    public function test_booking_has_duration_in_hours()
    {
        $booking = Booking::factory()->create([
            'start_time' => '09:00',
            'end_time' => '12:00',
            'duration_hours' => 3,
        ]);

        $this->assertEquals(3, $booking->duration_hours);
    }

    public function test_booking_has_dates()
    {
        $booking = Booking::factory()->create([
            'date' => '2025-03-15',
        ]);

        $this->assertEquals('2025-03-15', $booking->date->format('Y-m-d'));
    }

    public function test_booking_has_total()
    {
        $booking = Booking::factory()->create([
            'total' => 150000,
        ]);

        $this->assertEquals(150000, $booking->total);
    }

    public function test_booking_has_notes()
    {
        $booking = Booking::factory()->create([
            'notes' => 'Need extra microphones',
        ]);

        $this->assertEquals('Need extra microphones', $booking->notes);
    }

    public function test_booking_can_be_paid()
    {
        $booking = Booking::factory()->create(['status' => 'pending']);

        $this->assertTrue($booking->canBePaid());
    }

    public function test_booking_cannot_be_paid_when_confirmed()
    {
        $booking = Booking::factory()->create(['status' => 'confirmed']);

        $this->assertFalse($booking->canBePaid());
    }
}
