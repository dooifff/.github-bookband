<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_code' => $this->booking_code,
            'user' => new UserResource($this->whenLoaded('user')),
            'studio' => new StudioResource($this->whenLoaded('studio')),
            'room' => new StudioRoomResource($this->whenLoaded('room')),
            'band' => $this->band ? [
                'id' => $this->band->id,
                'name' => $this->band->name,
            ] : null,
            'date' => $this->date,
            'start_time' => $this->start_time,
            'end_time' => $this->end_time,
            'duration_minutes' => $this->duration_hours * 60,
            'duration_hours' => $this->duration_hours,
            'pricing' => [
                'subtotal' => $this->subtotal,
                'discount' => $this->discount,
                'total' => $this->total,
                'formatted_subtotal' => 'Rp ' . number_format($this->subtotal, 0, ',', '.'),
                'formatted_discount' => 'Rp ' . number_format($this->discount, 0, ',', '.'),
                'formatted_total' => 'Rp ' . number_format($this->total, 0, ',', '.'),
            ],
            'promo_code' => $this->promo_code,
            'payment' => $this->whenLoaded('payment') && $this->payment ? new PaymentResource($this->payment) : null,
            'status' => $this->status,
            'status_label' => $this->status_label,
            'notes' => $this->notes,
            'cancellation_reason' => $this->cancel_reason,
            'cancelled_at' => $this->cancelled_at?->toISOString(),
            'confirmed_at' => $this->confirmed_at?->toISOString(),
            'completed_at' => $this->completed_at?->toISOString(),
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
        ];
    }
}
