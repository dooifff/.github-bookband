<?php

namespace Database\Factories;

use App\Models\Studio;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudioRoomFactory extends Factory
{
    public function definition(): array
    {
        $roomTypes = ['Recording Room', 'Practice Room', 'Mixing Room', 'Rehearsal Room', 'VIP Room'];
        
        return [
            'studio_id' => Studio::factory(),
            'name' => fake()->randomElement($roomTypes) . ' ' . fake()->numberBetween(1, 5),
            'description' => fake()->paragraph(),
            'capacity' => fake()->numberBetween(2, 20),
            'price_per_hour' => fake()->randomElement([100000, 150000, 200000, 250000, 300000, 350000, 400000]),
            'is_active' => true,
        ];
    }
}
