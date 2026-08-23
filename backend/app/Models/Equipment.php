<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Equipment extends Model
{
    use HasFactory;

    protected $fillable = [
        'studio_id',
        'room_id',
        'name',
        'description',
        'brand',
        'model',
        'image',
        'is_included',
        'additional_price',
        'is_active',
    ];

    protected $casts = [
        'is_included' => 'boolean',
        'additional_price' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }

    public function room()
    {
        return $this->belongsTo(StudioRoom::class, 'room_id');
    }
}
