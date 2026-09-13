<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudioResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $canViewSubscription = $request->user()
            && ($request->user()->id === $this->owner_id
                || in_array($request->user()->role, ['admin', 'super_admin'], true));

        return [
            'id' => $this->id,
            'owner_id' => $this->owner_id,
            'name' => $this->name,
            'slug' => $this->slug,
            'description' => $this->description,
            'address' => $this->address,
            'city' => $this->city,
            'province' => $this->province,
            'full_address' => $this->full_address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'phone' => $this->phone,
            'email' => $this->email,
            'logo' => $this->logo,
            'is_verified' => $this->is_verified,
            'is_active' => $this->is_active,
            'average_rating' => $this->average_rating,
            'total_reviews' => $this->total_reviews,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
            // Subscription (owner/admin only)
            'subscription' => $this->when($canViewSubscription, [
                'status' => $this->subscription_status,
                'expires_at' => $this->subscription_expires_at?->toIso8601String(),
                'warning_level' => $this->subscription_warning_level,
                'last_warning_at' => $this->subscription_last_warning_at?->toIso8601String(),
            ]),
            // Relations (when loaded)
            'owner' => new UserResource($this->whenLoaded('owner')),
            'rooms' => StudioRoomResource::collection($this->whenLoaded('rooms')),
            'rooms_count' => $this->when(
                $request->user() && ($request->user()->id === $this->owner_id
                    || in_array($request->user()->role, ['admin', 'super_admin'], true)),
                $this->rooms_count ?? ($this->relationLoaded('rooms') ? $this->rooms->count() : 0)
            ),
            'active_rooms_count' => $this->when(
                $request->user() && ($request->user()->id === $this->owner_id
                    || in_array($request->user()->role, ['admin', 'super_admin'], true)),
                $this->active_rooms_count ?? ($this->relationLoaded('rooms') ? $this->rooms->where('is_active', true)->count() : 0)
            ),
            'images' => StudioImageResource::collection($this->whenLoaded('images')),
            'opening_hours' => OpeningHourResource::collection($this->whenLoaded('openingHours')),
            'equipment' => EquipmentResource::collection($this->whenLoaded('equipment')),
            'facilities' => FacilityResource::collection($this->whenLoaded('facilities')),
        ];
    }
}
