<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\ScheduleService;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\OpeningHour;
use App\Models\Booking;
use App\Models\BlockedSchedule;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ScheduleServiceTest extends TestCase
{
    use RefreshDatabase;

    protected $scheduleService;
    protected $studio;
    protected $room;

    protected function setUp(): void
    {
        parent::setUp();
        $this->scheduleService = new ScheduleService();
        $this->studio = Studio::factory()->create();
        $this->room = StudioRoom::factory()->create(['studio_id' => $this->studio->id]);
    }

    public function test_check_availability_returns_available()
    {
        // Setup opening hours for Monday
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        $result = $this->scheduleService->checkAvailability(
            $this->studio->id,
            $this->room->id,
            '2025-03-17', // Monday
            '10:00',
            '12:00'
        );

        $this->assertTrue($result['available']);
    }

    public function test_check_availability_returns_unavailable_when_closed()
    {
        // Setup opening hours for Monday - closed
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'is_closed' => true,
        ]);

        $result = $this->scheduleService->checkAvailability(
            $this->studio->id,
            $this->room->id,
            '2025-03-17', // Monday
            '10:00',
            '12:00'
        );

        $this->assertFalse($result['available']);
        $this->assertStringContainsString('tidak buka', $result['message']);
    }

    public function test_check_availability_returns_unavailable_when_booked()
    {
        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        // Create existing booking
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'booking_date' => '2025-03-17',
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $result = $this->scheduleService->checkAvailability(
            $this->studio->id,
            $this->room->id,
            '2025-03-17',
            '11:00',
            '13:00'
        );

        $this->assertFalse($result['available']);
        $this->assertStringContainsString('sudah dipesan', $result['message']);
    }

    public function test_check_availability_returns_unavailable_when_blocked()
    {
        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        // Create blocked schedule
        \App\Models\BlockedSchedule::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'blocked_date' => '2025-03-17',
            'start_time' => '10:00',
            'end_time' => '12:00',
        ]);

        $result = $this->scheduleService->checkAvailability(
            $this->studio->id,
            $this->room->id,
            '2025-03-17',
            '11:00',
            '13:00'
        );

        $this->assertFalse($result['available']);
        $this->assertStringContainsString('diblokir', $result['message']);
    }

    public function test_get_available_slots_returns_slots()
    {
        // Setup opening hours
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '12:00',
            'is_closed' => false,
        ]);

        $slots = $this->scheduleService->getAvailableSlots(
            $this->studio->id,
            $this->room->id,
            '2025-03-17'
        );

        $this->assertIsArray($slots);
        $this->assertNotEmpty($slots);
        $this->assertArrayHasKey('start', $slots[0]);
        $this->assertArrayHasKey('end', $slots[0]);
        $this->assertArrayHasKey('available', $slots[0]);
    }

    public function test_has_booking_conflict_returns_true_when_conflict()
    {
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'booking_date' => '2025-03-17',
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $hasConflict = $this->scheduleService->hasBookingConflict(
            $this->studio->id,
            $this->room->id,
            '2025-03-17',
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
            'booking_date' => '2025-03-17',
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        $hasConflict = $this->scheduleService->hasBookingConflict(
            $this->studio->id,
            $this->room->id,
            '2025-03-17',
            '14:00',
            '16:00'
        );

        $this->assertFalse($hasConflict);
    }

    public function test_is_studio_open_returns_true_when_open()
    {
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        $isOpen = $this->scheduleService->isStudioOpen($this->studio->id, '2025-03-17');

        $this->assertTrue($isOpen);
    }

    public function test_is_studio_open_returns_false_when_closed()
    {
        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'is_closed' => true,
        ]);

        $isOpen = $this->scheduleService->isStudioOpen($this->studio->id, '2025-03-17');

        $this->assertFalse($isOpen);
    }
}
