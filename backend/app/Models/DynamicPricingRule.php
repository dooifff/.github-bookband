<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class DynamicPricingRule extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'studio_room_id',
        'name',
        'description',
        'multiplier',
        'priority',
        'days_of_week',
        'start_date',
        'end_date',
        'start_time',
        'end_time',
        'is_active',
    ];

    protected $casts = [
        'days_of_week' => 'array',
        'multiplier' => 'float',
        'priority' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Get the room that owns the rule
     */
    public function room()
    {
        return $this->belongsTo(StudioRoom::class, 'studio_room_id');
    }

    /**
     * Check if rule applies to a specific date and time
     */
    public function appliesTo(string $date, string $time): bool
    {
        if (!$this->is_active) {
            return false;
        }

        $carbon = \Carbon\Carbon::parse($date . ' ' . $time);
        $dayOfWeek = $carbon->dayOfWeek;
        $timeStr = $carbon->format('H:i:s');

        // Check day of week
        if ($this->days_of_week && !in_array($dayOfWeek, $this->days_of_week)) {
            return false;
        }

        // Check date range
        if ($this->start_date && $date < $this->start_date) {
            return false;
        }
        if ($this->end_date && $date > $this->end_date) {
            return false;
        }

        // Check time range
        if ($this->start_time && $timeStr < $this->start_time) {
            return false;
        }
        if ($this->end_time && $timeStr > $this->end_time) {
            return false;
        }

        return true;
    }

    /**
     * Get discount percentage
     */
    public function getDiscountPercentageAttribute(): float
    {
        if ($this->multiplier < 1) {
            return round((1 - $this->multiplier) * 100, 1);
        }
        return 0;
    }

    /**
     * Get surcharge percentage
     */
    public function getSurchargePercentageAttribute(): float
    {
        if ($this->multiplier > 1) {
            return round(($this->multiplier - 1) * 100, 1);
        }
        return 0;
    }

    /**
     * Scope: active rules
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope: rules by priority
     */
    public function scopeByPriority($query)
    {
        return $query->orderBy('priority', 'desc');
    }
}
