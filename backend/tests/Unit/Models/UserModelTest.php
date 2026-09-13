<?php

namespace Tests\Unit\Models;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class UserModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_has_name()
    {
        $user = User::factory()->create(['name' => 'John Doe']);

        $this->assertEquals('John Doe', $user->name);
    }

    public function test_user_has_email()
    {
        $user = User::factory()->create(['email' => 'john@example.com']);

        $this->assertEquals('john@example.com', $user->email);
    }

    public function test_user_has_role()
    {
        $user = User::factory()->create(['role' => 'customer']);

        $this->assertEquals('customer', $user->role);
    }

    public function test_user_password_is_hashed()
    {
        $user = User::factory()->create(['password' => 'secret123']);

        $this->assertTrue(Hash::check('secret123', $user->password));
    }

    public function test_user_is_owner()
    {
        $user = User::factory()->create(['role' => 'owner']);

        $this->assertTrue($user->isOwner());
    }

    public function test_user_is_not_owner()
    {
        $user = User::factory()->create(['role' => 'customer']);

        $this->assertFalse($user->isOwner());
    }

    public function test_user_is_admin()
    {
        $user = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($user->isAdmin());
    }

    public function test_user_is_super_admin()
    {
        $user = User::factory()->create(['role' => 'super_admin']);

        $this->assertTrue($user->isSuperAdmin());
    }

    public function test_user_has_studios()
    {
        $user = User::factory()->create(['role' => 'owner']);
        $studio = \App\Models\Studio::factory()->create(['owner_id' => $user->id]);

        $this->assertTrue($user->ownedStudios->contains($studio));
    }

    public function test_user_has_bookings()
    {
        $user = User::factory()->create();
        $booking = \App\Models\Booking::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->bookings->contains($booking));
    }

    public function test_user_has_reviews()
    {
        $user = User::factory()->create();
        $review = \App\Models\Review::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->reviews->contains($review));
    }

    public function test_user_has_favorites()
    {
        $user = User::factory()->create();
        $favorite = \App\Models\Favorite::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->favorites->contains($favorite));
    }

    public function test_user_has_bands()
    {
        $user = User::factory()->create();
        $band = \App\Models\Band::factory()->create(['owner_id' => $user->id]);
        $user->bands()->attach($band->id, ['role' => 'owner']);

        $this->assertTrue($user->bands->contains($band));
    }

    public function test_user_can_be_verified()
    {
        $user = User::factory()->create(['email_verified_at' => null]);

        $this->assertFalse($user->hasVerifiedEmail());

        $user->markEmailAsVerified();

        $this->assertTrue($user->hasVerifiedEmail());
    }

    public function test_user_has_notifications()
    {
        $user = User::factory()->create();
        $notification = \App\Models\Notification::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->notifications->contains($notification));
    }

    public function test_user_has_phone()
    {
        $user = User::factory()->create(['phone' => '08123456789']);

        $this->assertEquals('08123456789', $user->phone);
    }
}
