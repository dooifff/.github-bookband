<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EquipmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'studio_id' => $this->studio_id,
            'room_id' => $this->room_id,
            'name' => $this->name,
            'description' => $this->description,
            'brand' => $this->brand,
            'model' => $this->model,
            'image' => $this->image,
            'is_included' => $this->is_included,
            'additional_price' => $this->additional_price,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
