<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudioImage extends Model
{
    use HasFactory;

    protected $table = 'studio_images';

    protected $fillable = [
        'studio_id',
        'url',
        'caption',
        'sort_order',
    ];

    protected $casts = [
        'sort_order' => 'integer',
    ];

    public function studio()
    {
        return $this->belongsTo(Studio::class);
    }
}
