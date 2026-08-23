<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'body',
        'data',
        'is_read',
        'read_at',
    ];

    protected $casts = [
        'data' => 'array',
        'is_read' => 'boolean',
        'read_at' => 'datetime',
    ];

    /*
    |----------------------------------------------------------------------
    | Constants
    |----------------------------------------------------------------------
    */

    const TYPE_BOOKING = 'booking';
    const TYPE_PAYMENT = 'payment';
    const TYPE_PROMO = 'promo';
    const TYPE_SYSTEM = 'system';

    /*
    |----------------------------------------------------------------------
    | Relationships
    |----------------------------------------------------------------------
    */

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /*
    |----------------------------------------------------------------------
    | Scopes
    |----------------------------------------------------------------------
    */

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public function scopeForType($query, string $type)
    {
        return $query->where('type', $type);
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function markAsRead(): void
    {
        $this->update([
            'is_read' => true,
            'read_at' => now(),
        ]);
    }

    public static function getUnreadCount(int $userId): int
    {
        return static::where('user_id', $userId)
            ->unread()
            ->count();
    }
}
