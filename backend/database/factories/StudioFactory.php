<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class StudioFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->company() . ' Studio';
        
        return [
            'owner_id' => User::factory()->owner(),
            'name' => $name,
            'slug' => Str::slug($name),
            'description' => fake()->paragraph(),
            'address' => fake()->address(),
            'city' => fake()->city(),
            'province' => fake()->state(),
            'latitude' => fake()->latitude(-6.2, -6.1),
            'longitude' => fake()->longitude(106.7, 106.9),
            'phone' => fake()->phoneNumber(),
            'email' => fake()->email(),
            'is_verified' => fake()->boolean(70),
            'is_active' => true,
            'average_rating' => fake()->randomFloat(2, 3.5, 5.0),
            'total_reviews' => fake()->numberBetween(0, 100),
        ];
    }

    public function verified(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_verified' => true,
        ]);
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_verified' => false,
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }
}
