<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudioImageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'studio_id' => $this->studio_id,
            'url' => $this->url,
            'caption' => $this->caption,
            'sort_order' => $this->sort_order,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
