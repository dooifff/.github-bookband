<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChatRoom extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'studio_id',
        'customer_id',
        'owner_id',
        'status',
        'last_message_at',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
    ];

    /**
     * Get the booking
     */
    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    /**
     * Get the studio
     */
    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }

    /**
     * Get the customer
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the owner
     */
    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Get messages
     */
    public function messages()
    {
        return $this->hasMany(ChatMessage::class, 'chat_room_id');
    }

    /**
     * Get unread messages count for a user
     */
    public function getUnreadCount(int $userId): int
    {
        return $this->messages()
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->count();
    }

    /**
     * Scope: active rooms
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    /**
     * Scope: for user
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('customer_id', $userId)
            ->orWhere('owner_id', $userId);
    }
}
