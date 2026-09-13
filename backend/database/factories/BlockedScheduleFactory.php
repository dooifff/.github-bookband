<?php

namespace Database\Factories;

use App\Models\Studio;
use App\Models\StudioRoom;
use Illuminate\Database\Eloquent\Factories\Factory;

class BlockedScheduleFactory extends Factory
{
    public function definition(): array
    {
        return [
            'studio_id' => Studio::factory(),
            'room_id' => StudioRoom::factory(),
            'date' => fake()->dateTimeBetween('+1 day', '+30 day')->format('Y-m-d'),
            'start_time' => '10:00',
            'end_time' => '12:00',
            'all_day' => false,
            'reason' => fake()->optional()->sentence(),
        ];
    }

    public function allDay(): static
    {
        return $this->state(fn (array $attributes) => [
            'all_day' => true,
            'start_time' => null,
            'end_time' => null,
        ]);
    }
}