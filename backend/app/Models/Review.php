<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Review extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'studio_id',
        'booking_id',
        'rating',
        'comment',
        'is_anonymous',
        'is_approved',
    ];

    protected $casts = [
        'rating' => 'integer',
        'is_anonymous' => 'boolean',
        'is_approved' => 'boolean',
    ];

    /*
    |----------------------------------------------------------------------
    | Relationships
    |----------------------------------------------------------------------
    */

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function images()
    {
        return $this->hasMany(ReviewImage::class)->orderBy('sort_order');
    }

    /*
    |----------------------------------------------------------------------
    | Scopes
    |----------------------------------------------------------------------
    */

    public function scopeApproved($query)
    {
        return $query->where('is_approved', true);
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function getDisplayNameAttribute(): string
    {
        return $this->is_anonymous ? 'Anonymous' : ($this->user->name ?? 'User');
    }

    protected static function boot()
    {
        parent::boot();

        static::created(function ($review) {
            $review->studio->recalculateRating();
        });

        static::deleted(function ($review) {
            $review->studio->recalculateRating();
        });
    }
}
