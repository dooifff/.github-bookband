<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class BandFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->words(2, true) . ' Band';
        $genres = ['Rock', 'Pop', 'Jazz', 'Metal', 'Blues', 'Folk', 'Electronic', 'Hip Hop', 'R&B', 'Reggae'];
        
        return [
            'owner_id' => User::factory()->customer(),
            'name' => $name,
            'slug' => Str::slug($name),
            'description' => fake()->paragraph(),
            'genre' => fake()->randomElement($genres),
            'is_active' => true,
        ];
    }
}
