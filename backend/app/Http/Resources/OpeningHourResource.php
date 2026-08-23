<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OpeningHourResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'studio_id' => $this->studio_id,
            'day_of_week' => $this->day_of_week,
            'day_name' => $this->day_name,
            'open_time' => $this->open_time,
            'close_time' => $this->close_time,
            'is_closed' => $this->is_closed,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
