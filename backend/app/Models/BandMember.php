<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BandMember extends Model
{
    use HasFactory;    protected $fillable = [
        'band_id', 'user_id', 'role', 'status', 'invited_by', 'invited_at', 'accepted_at',
    ];

    protected $casts = [
        'invited_at' => 'datetime',
        'accepted_at' => 'datetime',
    ];

    public function band()
    {
        return $this->belongsTo(Band::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
