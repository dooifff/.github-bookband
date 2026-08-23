<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\BookingService;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\OpeningHour;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

class BookingServiceTest extends TestCase
{
    use RefreshDatabase;

    protected $bookingService;
    protected $user;
    protected $studio;
    protected $room;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bookingService = new BookingService();
        $this->user = User::factory()->create(['role' => 'customer']);
        $this->studio = Studio::factory()->create();
        $this->room = StudioRoom::factory()->create([
            'studio_id' => $this->studio->id,
            'price_per_hour' => 50000,
        ]);

        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);
    }

    public function test_create_booking_successfully()
    {
        $data = [
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => '2025-03-17', // Monday
            'start_time' => '10:00',
            'end_time' => '12:00',
            'notes' => 'Test booking',
        ];

        $booking = $this->bookingService->createBooking($data);

        $this->assertNotNull($booking);
        $this->assertEquals('pending', $booking->status);
        $this->assertEquals(100000, $booking->total); // 2 hours * 50000
        $this->assertNotEmpty($booking->booking_code);
    }

    public function test_create_booking_fails_when_no_availability()
    {
        // Create existing booking
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => '2025-03-17',
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $data = [
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => '2025-03-17',
            'start_time' => '11:00',
            'end_time' => '13:00',
        ];

        $this->expectException(\Exception::class);

        $this->bookingService->createBooking($data);
    }

    public function test_cancel_booking_successfully()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'confirmed',
        ]);

        $result = $this->bookingService->cancelBooking($booking);

        $this->assertTrue($result);
        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'cancelled',
        ]);
    }

    public function test_cancel_booking_fails_when_not_cancellable()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'ongoing',
        ]);

        $this->expectException(\Exception::class);

        $this->bookingService->cancelBooking($booking);
    }

    public function test_generate_unique_booking_code()
    {
        $code1 = $this->bookingService->generateBookingCode();
        $code2 = $this->bookingService->generateBookingCode();

        $this->assertNotEquals($code1, $code2);
        $this->assertEquals(8, strlen($code1));
        $this->assertEquals(8, strlen($code2));
    }

    public function test_calculate_total_amount()
    {
        $amount = $this->bookingService->calculateTotalAmount(
            $this->room->id,
            '10:00',
            '12:00'
        );

        $this->assertEquals(100000, $amount); // 2 hours * 50000
    }

    public function test_calculate_total_amount_with_different_times()
    {
        $amount = $this->bookingService->calculateTotalAmount(
            $this->room->id,
            '09:00',
            '15:00'
        );

        $this->assertEquals(300000, $amount); // 6 hours * 50000
    }
}
