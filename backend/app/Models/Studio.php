<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Studio extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'owner_id',
        'name',
        'slug',
        'description',
        'address',
        'city',
        'province',
        'latitude',
        'longitude',
        'phone',
        'email',
        'logo',
        'is_verified',
        'is_active',
        'average_rating',
        'total_reviews',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'is_verified' => 'boolean',
        'is_active' => 'boolean',
        'average_rating' => 'float',
        'total_reviews' => 'integer',
    ];

    protected $hidden = [
        'deleted_at',
    ];

    // Auto-generate slug
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($studio) {
            if (empty($studio->slug)) {
                $studio->slug = Str::slug($studio->name);
                $count = static::where('slug', 'like', $studio->slug . '%')->count();
                if ($count > 0) {
                    $studio->slug .= '-' . ($count + 1);
                }
            }
        });
    }

    /*
    |----------------------------------------------------------------------
    | Relationships
    |----------------------------------------------------------------------
    */

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function rooms()
    {
        return $this->hasMany(StudioRoom::class);
    }

    public function images()
    {
        return $this->hasMany(StudioImage::class)->orderBy('sort_order');
    }

    public function equipment()
    {
        return $this->hasMany(Equipment::class);
    }

    public function openingHours()
    {
        return $this->hasMany(OpeningHour::class)->orderBy('day_of_week');
    }

    public function blockedSchedules()
    {
        return $this->hasMany(BlockedSchedule::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function favorites()
    {
        return $this->hasMany(Favorite::class);
    }

    public function promos()
    {
        return $this->hasMany(Promo::class);
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function getFullAddressAttribute(): string
    {
        return collect([$this->address, $this->city, $this->province])
            ->filter()
            ->implode(', ');
    }

    public function recalculateRating(): void
    {
        $stats = $this->reviews()->selectRaw('AVG(rating) as avg_rating, COUNT(*) as total')
            ->first();

        $this->update([
            'average_rating' => round($stats->avg_rating ?? 0, 2),
            'total_reviews' => $stats->total ?? 0,
        ]);
    }
}
