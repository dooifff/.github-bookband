<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OpeningHour extends Model
{
    use HasFactory;

    protected $table = 'opening_hours';

    protected $fillable = [
        'studio_id',
        'day_of_week',
        'open_time',
        'close_time',
        'is_closed',
    ];

    protected $casts = [
        'day_of_week' => 'integer',
        'is_closed' => 'boolean',
    ];

    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }

    /**
     * Check if studio is open at given time
     */
    public function isOpenAt(string $time): bool
    {
        if ($this->is_closed) {
            return false;
        }

        return $time >= $this->open_time && $time <= $this->close_time;
    }

    /**
     * Get day name
     */
    public function getDayNameAttribute(): string
    {
        $days = [
            0 => 'Minggu',
            1 => 'Senin',
            2 => 'Selasa',
            3 => 'Rabu',
            4 => 'Kamis',
            5 => 'Jumat',
            6 => 'Sabtu',
        ];

        return $days[$this->day_of_week] ?? '';
    }
}
