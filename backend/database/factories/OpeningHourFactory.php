<?php

namespace Database\Factories;

use App\Models\Studio;
use Illuminate\Database\Eloquent\Factories\Factory;

class OpeningHourFactory extends Factory
{
    public function definition(): array
    {
        return [
            'studio_id' => Studio::factory(),
            'day_of_week' => fake()->numberBetween(0, 6),
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ];
    }

    public function closed(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_closed' => true,
            'open_time' => null,
            'close_time' => null,
        ]);
    }
}
