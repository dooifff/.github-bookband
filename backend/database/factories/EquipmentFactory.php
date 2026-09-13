<?php

namespace Database\Factories;

use App\Models\Studio;
use App\Models\StudioRoom;
use Illuminate\Database\Eloquent\Factories\Factory;

class EquipmentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'studio_id' => Studio::factory(),
            'room_id' => StudioRoom::factory(),
            'name' => fake()->randomElement(['Drum Set', 'Gitar Elektrik', 'Bass', 'Keyboard', 'Amplifier', 'Microphone', 'Mixer', 'Monitor Speaker']),
            'description' => fake()->optional()->sentence(),
            'brand' => fake()->optional()->company(),
            'model' => fake()->optional()->bothify('##-??'),
            'image' => fake()->optional()->imageUrl(),
            'is_included' => fake()->boolean(70),
            'additional_price' => fake()->boolean(30) ? fake()->randomFloat(2, 50000, 500000) : 0,
            'is_active' => true,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }
}