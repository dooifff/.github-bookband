<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\BookingService;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Booking;
use App\Models\OpeningHour;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Carbon\Carbon;
use InvalidArgumentException;

class BookingServiceTest extends TestCase
{
    use RefreshDatabase;

    protected $bookingService;
    protected $user;
    protected $studio;
    protected $room;
    protected $date;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bookingService = new BookingService();
        $this->user = User::factory()->create(['role' => 'customer']);
        $this->studio = Studio::factory()->create([
            'is_active' => true,
            'is_verified' => true,
        ]);
        $this->room = StudioRoom::factory()->create([
            'studio_id' => $this->studio->id,
            'price_per_hour' => 50000,
        ]);

        // Use a future Monday so the date is valid and the studio is open
        $this->date = now()->next(Carbon::MONDAY)->format('Y-m-d');
        $dayOfWeek = Carbon::parse($this->date)->dayOfWeekIso; // 1 = Monday

        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => $dayOfWeek,
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);
    }

    public function test_create_booking_successfully()
    {
        $data = [
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
            'notes' => 'Test booking',
        ];

        $booking = $this->bookingService->createBooking($data, $this->user);

        $this->assertNotNull($booking);
        $this->assertEquals('pending', $booking->status);
        $this->assertEquals(100000, (float) $booking->total); // 2 hours * 50000
        $this->assertNotEmpty($booking->booking_code);
        $this->assertEquals($this->user->id, $booking->user_id);
    }

    public function test_create_booking_calculates_total_amount()
    {
        $data = [
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '09:00',
            'end_time' => '15:00',
        ];

        $booking = $this->bookingService->createBooking($data, $this->user);

        $this->assertEquals(300000, (float) $booking->total); // 6 hours * 50000
    }

    public function test_create_booking_fails_when_no_availability()
    {
        // Create existing booking
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $data = [
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '11:00',
            'end_time' => '13:00',
        ];

        $this->expectException(InvalidArgumentException::class);

        $this->bookingService->createBooking($data, $this->user);
    }

    public function test_cancel_booking_successfully()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'status' => 'pending',
        ]);

        $result = $this->bookingService->cancelBooking($booking, $this->user);

        $this->assertInstanceOf(Booking::class, $result);
        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'cancelled',
        ]);
    }

    public function test_cancel_booking_fails_when_not_cancellable()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'status' => 'confirmed',
        ]);

        $this->expectException(InvalidArgumentException::class);

        $this->bookingService->cancelBooking($booking, $this->user);
    }

    public function test_generate_unique_booking_code()
    {
        $data = [
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
        ];

        $booking1 = $this->bookingService->createBooking($data, $this->user);

        $data['start_time'] = '13:00';
        $data['end_time'] = '15:00';
        $booking2 = $this->bookingService->createBooking($data, $this->user);

        $this->assertNotEquals($booking1->booking_code, $booking2->booking_code);
        $this->assertStringStartsWith('SB', $booking1->booking_code);
        $this->assertStringStartsWith('SB', $booking2->booking_code);
    }
}