<?php

namespace Database\Factories;

use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class BlockedScheduleFactory extends Factory
{
    public function definition(): array
    {
        return [
            'studio_id' => Studio::factory(),
            'room_id' => StudioRoom::factory(),
            'user_id' => User::factory()->owner(),
            'blocked_date' => fake()->dateTimeBetween('+1 day', '+30 day')->format('Y-m-d'),
            'start_time' => '10:00',
            'end_time' => '12:00',
            'reason' => fake()->optional()->sentence(),
            'is_recurring' => false,
        ];
    }

    public function recurring(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_recurring' => true,
            'recurrence_pattern' => fake()->randomElement(['weekly', 'monthly']),
        ]);
    }
}
