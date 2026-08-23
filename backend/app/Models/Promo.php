<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Promo extends Model
{
    use HasFactory;

    protected $fillable = [
        'studio_id',
        'code',
        'name',
        'description',
        'type',
        'value',
        'min_booking_amount',
        'max_discount',
        'usage_limit',
        'usage_count',
        'per_user_limit',
        'start_date',
        'end_date',
        'is_active',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'min_booking_amount' => 'decimal:2',
        'max_discount' => 'decimal:2',
        'usage_limit' => 'integer',
        'usage_count' => 'integer',
        'per_user_limit' => 'integer',
        'start_date' => 'date',
        'end_date' => 'date',
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

    /*
    |----------------------------------------------------------------------
    | Scopes
    |----------------------------------------------------------------------
    */

    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now());
    }

    public function scopeForStudio($query, int $studioId)
    {
        return $query->where(function ($q) use ($studioId) {
            $q->where('studio_id', $studioId)
              ->orWhereNull('studio_id');
        });
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function isValid(): bool
    {
        if (!$this->is_active) {
            return false;
        }

        $now = now();
        if ($now->lt($this->start_date) || $now->gt($this->end_date)) {
            return false;
        }

        if ($this->usage_limit && $this->usage_count >= $this->usage_limit) {
            return false;
        }

        return true;
    }

    public function calculateDiscount(float $amount): float
    {
        if ($amount < $this->min_booking_amount) {
            return 0;
        }

        $discount = 0;
        if ($this->type === 'percentage') {
            $discount = $amount * ($this->value / 100);
            if ($this->max_discount && $discount > $this->max_discount) {
                $discount = $this->max_discount;
            }
        } else {
            $discount = $this->value;
        }

        return min($discount, $amount);
    }

    public function incrementUsage(): void
    {
        $this->increment('usage_count');
    }
}
