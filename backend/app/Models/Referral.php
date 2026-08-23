<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Referral extends Model
{
    use HasFactory;

    protected $fillable = [
        'referrer_id',
        'referred_id',
        'code',
        'is_active',
        'referred_at',
        'total_earned',
        'pending_earned',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'referred_at' => 'datetime',
        'total_earned' => 'decimal:2',
        'pending_earned' => 'decimal:2',
    ];

    /**
     * Get the referrer user
     */
    public function referrer()
    {
        return $this->belongsTo(User::class, 'referrer_id');
    }

    /**
     * Get the referred user
     */
    public function referred()
    {
        return $this->belongsTo(User::class, 'referred_id');
    }
}
