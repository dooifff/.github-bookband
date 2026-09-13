<?php

namespace Tests\Unit\Models;

use Tests\TestCase;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\User;
use App\Models\Booking;
use App\Models\Review;
use App\Models\OpeningHour;
use App\Models\Equipment;
use App\Models\Favorite;
use App\Models\Promo;
use App\Models\Band;
use Illuminate\Foundation\Testing\RefreshDatabase;

class StudioModelTest extends TestCase
{
    use RefreshDatabase;

    protected $studio;

    protected function setUp(): void
    {
        parent::setUp();
        $this->studio = Studio::factory()->create();
    }

    public function test_studio_belongs_to_owner()
    {
        $owner = User::factory()->create(['role' => 'owner']);
        $studio = Studio::factory()->create(['owner_id' => $owner->id]);

        $this->assertInstanceOf(User::class, $studio->owner);
        $this->assertEquals($owner->id, $studio->owner->id);
    }

    public function test_studio_has_many_rooms()
    {
        $room = StudioRoom::factory()->create(['studio_id' => $this->studio->id]);

        $this->assertTrue($this->studio->rooms->contains($room));
    }

    public function test_studio_has_many_images()
    {
        $image = $this->studio->images()->create([
            'url' => 'https://example.com/image.jpg',
            'is_primary' => true,
        ]);

        $this->assertTrue($this->studio->images->contains($image));
    }

    public function test_studio_has_many_equipment()
    {
        $room = StudioRoom::factory()->create(['studio_id' => $this->studio->id]);
        $equipment = Equipment::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $room->id,
        ]);

        $this->assertTrue($this->studio->equipment->contains($equipment));
    }

    public function test_studio_has_many_opening_hours()
    {
        $openingHour = OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
        ]);

        $this->assertTrue($this->studio->openingHours->contains($openingHour));
    }

    public function test_studio_has_many_bookings()
    {
        $room = StudioRoom::factory()->create(['studio_id' => $this->studio->id]);
        $booking = Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $room->id,
        ]);

        $this->assertTrue($this->studio->bookings->contains($booking));
    }

    public function test_studio_has_many_reviews()
    {
        $review = Review::factory()->create([
            'studio_id' => $this->studio->id,
        ]);

        $this->assertTrue($this->studio->reviews->contains($review));
    }

    public function test_studio_has_many_favorites()
    {
        $user = User::factory()->create();
        $favorite = Favorite::factory()->create([
            'user_id' => $user->id,
            'studio_id' => $this->studio->id,
        ]);

        $this->assertTrue($this->studio->favorites->contains($favorite));
    }

    public function test_studio_generates_slug_from_name()
    {
        $studio = Studio::factory()->create(['name' => 'Studio Musik Jaya']);

        $this->assertEquals('studio-musik-jaya', $studio->slug);
    }

    public function test_studio_has_primary_image()
    {
        $this->studio->images()->create([
            'url' => 'https://example.com/primary.jpg',
            'is_primary' => true,
        ]);
        $this->studio->images()->create([
            'url' => 'https://example.com/secondary.jpg',
            'is_primary' => false,
        ]);

        $primary = $this->studio->images()->where('is_primary', true)->first();
        $this->assertNotNull($primary);
        $this->assertTrue($primary->is_primary);
    }

    public function test_studio_is_active_by_default()
    {
        $studio = Studio::factory()->create();

        $this->assertTrue($studio->is_active);
    }

    public function test_studio_soft_deletes()
    {
        $studio = Studio::factory()->create();
        $studioId = $studio->id;

        $studio->delete();

        $this->assertSoftDeleted('studios', ['id' => $studioId]);
    }

    public function test_studio_has_address_full_attribute()
    {
        $studio = Studio::factory()->create([
            'address' => 'Jl. Test No. 123',
            'city' => 'Jakarta',
            'province' => 'DKI Jakarta',
        ]);

        $this->assertEquals('Jl. Test No. 123, Jakarta, DKI Jakarta', $studio->full_address);
    }

    public function test_studio_calculates_average_rating()
    {
        Review::factory()->count(3)->create([
            'studio_id' => $this->studio->id,
            'rating' => 4,
        ]);

        $this->studio->refresh();
        $this->assertEquals(4.0, $this->studio->average_rating);
    }

    public function test_studio_has_total_reviews_count()
    {
        Review::factory()->count(5)->create([
            'studio_id' => $this->studio->id,
        ]);

        $this->studio->refresh();
        $this->assertEquals(5, $this->studio->total_reviews);
    }
}
