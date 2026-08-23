<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'user_id',
        'payment_code',
        'provider',
        'provider_payment_id',
        'payment_url',
        'amount',
        'status',
        'payment_method',
        'payment_type',
        'paid_at',
        'expired_at',
        'raw_response',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'paid_at' => 'datetime',
        'expired_at' => 'datetime',
        'raw_response' => 'array',
    ];

    protected $hidden = [
        'raw_response',
    ];

    // Statuses
    const STATUS_PENDING = 'pending';
    const STATUS_PAID = 'paid';
    const STATUS_FAILED = 'failed';
    const STATUS_EXPIRED = 'expired';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_REFUNDED = 'refunded';

    // Auto-generate payment code
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($payment) {
            if (empty($payment->payment_code)) {
                $payment->payment_code = 'PAY' . strtoupper(Str::random(8));
            }
        });
    }

    /*
    |----------------------------------------------------------------------
    | Relationships
    |----------------------------------------------------------------------
    */

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function getFormattedAmountAttribute(): string
    {
        return 'Rp ' . number_format($this->amount, 0, ',', '.');
    }

    public function markAsPaid(string $method = null, string $type = null): void
    {
        $this->update([
            'status' => self::STATUS_PAID,
            'payment_method' => $method,
            'payment_type' => $type,
            'paid_at' => now(),
        ]);

        // Update booking status
        $this->booking->markAsPaid();
    }

    public function markAsFailed(): void
    {
        $this->update(['status' => self::STATUS_FAILED]);
    }

    public function markAsExpired(): void
    {
        $this->update(['status' => self::STATUS_EXPIRED]);
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isPaid(): bool
    {
        return $this->status === self::STATUS_PAID;
    }
}
