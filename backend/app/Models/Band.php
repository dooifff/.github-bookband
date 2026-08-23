<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Band extends Model
{
    use HasFactory, SoftDeletes;    protected $fillable = [
        'owner_id', 'name', 'slug', 'description', 'logo', 'genre', 'is_active', 'status',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected $hidden = [
        'deleted_at',
    ];

    // Auto-generate slug
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($band) {
            if (empty($band->slug)) {
                $band->slug = Str::slug($band->name);
                $count = static::where('slug', 'like', $band->slug . '%')->count();
                if ($count > 0) {
                    $band->slug .= '-' . ($count + 1);
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

    public function members()
    {
        return $this->hasMany(BandMember::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function getMemberCountAttribute(): int
    {
        return $this->members()->where('status', 'accepted')->count();
    }

    public function isMember(User $user): bool
    {
        return $this->members()->where('user_id', $user->id)->exists();
    }

    public function isOwner(User $user): bool
    {
        return $this->owner_id === $user->id;
    }
}
