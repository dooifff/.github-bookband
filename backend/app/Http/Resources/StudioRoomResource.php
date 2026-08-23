<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudioRoomResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'studio_id' => $this->studio_id,
            'name' => $this->name,
            'description' => $this->description,
            'capacity' => $this->capacity,
            'price_per_hour' => $this->price_per_hour,
            'formatted_price' => $this->formatted_price,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
            // Relations
            'equipment' => EquipmentResource::collection($this->whenLoaded('equipment')),
        ];
    }
}
