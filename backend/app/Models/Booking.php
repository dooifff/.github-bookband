<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Booking extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'studio_id',
        'room_id',
        'band_id',
        'booking_code',
        'date',
        'start_time',
        'end_time',
        'duration_hours',
        'price_per_hour',
        'subtotal',
        'discount',
        'total',
        'status',
        'promo_code',
        'notes',
        'cancel_reason',
        'cancelled_at',
        'paid_at',
        'confirmed_at',
        'completed_at',
    ];

    protected $casts = [
        'date' => 'date',
        'duration_hours' => 'integer',
        'price_per_hour' => 'decimal:2',
        'subtotal' => 'decimal:2',
        'discount' => 'decimal:2',
        'total' => 'decimal:2',
        'cancelled_at' => 'datetime',
        'paid_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    protected $hidden = [
        'deleted_at',
    ];

    // Statuses
    const STATUS_PENDING = 'pending';
    const STATUS_AWAITING_PAYMENT = 'awaiting_payment';
    const STATUS_PAID = 'paid';
    const STATUS_CONFIRMED = 'confirmed';
    const STATUS_ONGOING = 'ongoing';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_EXPIRED = 'expired';
    const STATUS_FAILED = 'failed';
    const STATUS_REFUNDED = 'refunded';

    // Auto-generate booking code
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($booking) {
            if (empty($booking->booking_code)) {
                $booking->booking_code = 'SB' . strtoupper(Str::random(8));
            }
        });
    }

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

    public function room()
    {
        return $this->belongsTo(StudioRoom::class, 'room_id');
    }

    public function band()
    {
        return $this->belongsTo(Band::class);
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }

    /*
    |----------------------------------------------------------------------
    | Scopes
    |----------------------------------------------------------------------
    */

    public function scopeUpcoming($query)
    {
        return $query->where('date', '>=', now()->toDateString())
            ->whereIn('status', [self::STATUS_PAID, self::STATUS_CONFIRMED]);
    }

    public function scopePast($query)
    {
        return $query->where('date', '<', now()->toDateString())
            ->orWhereIn('status', [self::STATUS_COMPLETED, self::STATUS_CANCELLED]);
    }

    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopePaid($query)
    {
        return $query->where('status', self::STATUS_PAID);
    }

    /*
    |----------------------------------------------------------------------
    | Helper Methods
    |----------------------------------------------------------------------
    */

    public function getFormattedTotalAttribute(): string
    {
        return 'Rp ' . number_format($this->total, 0, ',', '.');
    }

    public function getStatusLabelAttribute(): string
    {
        $labels = [
            self::STATUS_PENDING => 'Pending',
            self::STATUS_AWAITING_PAYMENT => 'Menunggu Pembayaran',
            self::STATUS_PAID => 'Dibayar',
            self::STATUS_CONFIRMED => 'Dikonfirmasi',
            self::STATUS_ONGOING => 'Berlangsung',
            self::STATUS_COMPLETED => 'Selesai',
            self::STATUS_CANCELLED => 'Dibatalkan',
            self::STATUS_EXPIRED => 'Kedaluwarsa',
            self::STATUS_FAILED => 'Gagal',
            self::STATUS_REFUNDED => 'Dikembalikan',
        ];

        return $labels[$this->status] ?? $this->status;
    }

    public function canBeCancelled(): bool
    {
        return in_array($this->status, [
            self::STATUS_PENDING,
            self::STATUS_AWAITING_PAYMENT,
            self::STATUS_PAID,
        ]);
    }

    public function canBePaid(): bool
    {
        return in_array($this->status, [
            self::STATUS_PENDING,
            self::STATUS_AWAITING_PAYMENT,
        ]);
    }

    public function markAsPaid(): void
    {
        $this->update([
            'status' => self::STATUS_PAID,
            'paid_at' => now(),
        ]);
    }

    public function markAsConfirmed(): void
    {
        $this->update([
            'status' => self::STATUS_CONFIRMED,
            'confirmed_at' => now(),
        ]);
    }

    public function markAsCompleted(): void
    {
        $this->update([
            'status' => self::STATUS_COMPLETED,
            'completed_at' => now(),
        ]);
    }

    public function cancel(string $reason = null): void
    {
        $this->update([
            'status' => self::STATUS_CANCELLED,
            'cancel_reason' => $reason,
            'cancelled_at' => now(),
        ]);
    }
}
