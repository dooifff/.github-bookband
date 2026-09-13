<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\ScheduleService;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\OpeningHour;
use App\Models\Booking;
use App\Models\BlockedSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Carbon\Carbon;

class ScheduleServiceTest extends TestCase
{
    use RefreshDatabase;

    protected $scheduleService;
    protected $studio;
    protected $room;
    protected $date;

    protected function setUp(): void
    {
        parent::setUp();
        $this->scheduleService = new ScheduleService();
        $this->studio = Studio::factory()->create();
        $this->room = StudioRoom::factory()->create(['studio_id' => $this->studio->id]);

        // Future Monday (dayOfWeek = 1, matching the opening hours below)
        $this->date = now()->next(Carbon::MONDAY)->format('Y-m-d');
    }

    public function test_check_availability_returns_available()
    {
        // Setup opening hours for the booking day
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        $result = $this->scheduleService->isRoomAvailable(
            $this->room->id,
            $this->date,
            '10:00',
            '12:00'
        );

        $this->assertTrue($result);
    }

    public function test_check_availability_returns_unavailable_when_closed()
    {
        // Setup opening hours for the booking day - closed
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'is_closed' => true,
        ]);

        $result = $this->scheduleService->isRoomAvailable(
            $this->room->id,
            $this->date,
            '10:00',
            '12:00'
        );

        $this->assertFalse($result);
    }

    public function test_check_availability_returns_unavailable_when_booked()
    {
        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        // Create existing booking
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $result = $this->scheduleService->isRoomAvailable(
            $this->room->id,
            $this->date,
            '11:00',
            '13:00'
        );

        $this->assertFalse($result);
    }

    public function test_check_availability_returns_unavailable_when_blocked()
    {
        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        // Create blocked schedule
        BlockedSchedule::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
        ]);

        $result = $this->scheduleService->isRoomAvailable(
            $this->room->id,
            $this->date,
            '11:00',
            '13:00'
        );

        $this->assertFalse($result);
    }

    public function test_get_available_slots_returns_slots()
    {
        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'open_time' => '09:00',
            'close_time' => '12:00',
            'is_closed' => false,
        ]);

        $slots = $this->scheduleService->getAvailableSlots(
            $this->room->id,
            $this->date
        );

        $this->assertIsArray($slots);
        $this->assertNotEmpty($slots);
        $this->assertArrayHasKey('start_time', $slots[0]);
        $this->assertArrayHasKey('end_time', $slots[0]);
        $this->assertArrayHasKey('is_available', $slots[0]);
    }

    public function test_has_booking_conflict_returns_true_when_conflict()
    {
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $hasConflict = $this->scheduleService->hasOverlappingBooking(
            $this->room->id,
            $this->date,
            '11:00',
            '13:00'
        );

        $this->assertTrue($hasConflict);
    }

    public function test_has_booking_conflict_returns_false_when_no_conflict()
    {
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $hasConflict = $this->scheduleService->hasOverlappingBooking(
            $this->room->id,
            $this->date,
            '14:00',
            '16:00'
        );

        $this->assertFalse($hasConflict);
    }

    public function test_is_studio_open_returns_true_when_open()
    {
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        $isOpen = $this->scheduleService->isStudioOpen(
            $this->studio->id,
            $this->date,
            '10:00',
            '12:00'
        );

        $this->assertTrue($isOpen);
    }

    public function test_is_studio_open_returns_false_when_closed()
    {
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => Carbon::parse($this->date)->dayOfWeek,
            'is_closed' => true,
        ]);

        $isOpen = $this->scheduleService->isStudioOpen(
            $this->studio->id,
            $this->date,
            '10:00',
            '12:00'
        );

        $this->assertFalse($isOpen);
    }
}