<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BlockedSchedule extends Model
{
    use HasFactory;

    protected $table = 'blocked_schedules';

    protected $fillable = [
        'studio_id',
        'room_id',
        'date',
        'start_time',
        'end_time',
        'all_day',
        'reason',
    ];

    protected $casts = [
        'date' => 'date',
        'all_day' => 'boolean',
    ];

    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }

    public function room()
    {
        return $this->belongsTo(StudioRoom::class, 'room_id');
    }

    /**
     * Check if given time overlaps with this block
     */
    public function overlaps(string $date, string $startTime, string $endTime): bool
    {
        if ($this->date->toDateString() !== $date) {
            return false;
        }

        if ($this->all_day) {
            return true;
        }

        return $startTime < $this->end_time && $endTime > $this->start_time;
    }
}
