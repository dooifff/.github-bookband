<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class StudioRoom extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'studio_rooms';

    protected $fillable = [
        'studio_id',
        'name',
        'description',
        'capacity',
        'price_per_hour',
        'is_active',
    ];

    protected $casts = [
        'capacity' => 'integer',
        'price_per_hour' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /*
    |----------------------------------------------------------------------
    | Relationships
    |----------------------------------------------------------------------
    */

    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }

    public function equipment()
    {
        return $this->hasMany(Equipment::class, 'room_id');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class, 'room_id');
    }

    public function blockedSchedules()
    {
        return $this->hasMany(BlockedSchedule::class, 'room_id');
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function getFormattedPriceAttribute(): string
    {
        return 'Rp ' . number_format($this->price_per_hour, 0, ',', '.') . '/jam';
    }

    /**
     * Check if room is available for given date and time
     */
    public function isAvailable(string $date, string $startTime, string $endTime): bool
    {
        // Check if room is active
        if (!$this->is_active) {
            return false;
        }

        // Check for overlapping bookings
        $overlapping = $this->bookings()
            ->where('date', $date)
            ->whereNotIn('status', ['cancelled', 'failed', 'expired'])
            ->where(function ($query) use ($startTime, $endTime) {
                $query->where(function ($q) use ($startTime, $endTime) {
                    $q->where('start_time', '<', $endTime)
                      ->where('end_time', '>', $startTime);
                });
            })
            ->exists();

        return !$overlapping;
    }
}
