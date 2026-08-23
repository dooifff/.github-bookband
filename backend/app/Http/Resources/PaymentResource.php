<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'payment_code' => $this->payment_code,
            'booking_id' => $this->booking_id,
            'amount' => $this->amount,
            'formatted_amount' => 'Rp ' . number_format($this->amount, 0, ',', '.'),
            'method' => $this->method,
            'provider' => $this->provider,
            'provider_reference' => $this->provider_reference,
            'status' => $this->status,
            'status_label' => $this->getStatusLabel(),
            'paid_at' => $this->paid_at?->toISOString(),
            'expires_at' => $this->expires_at?->toISOString(),
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
        ];
    }

    private function getStatusLabel(): string
    {
        return match($this->status) {
            'pending' => 'Menunggu Pembayaran',
            'processing' => 'Diproses',
            'paid' => 'Lunas',
            'failed' => 'Gagal',
            'expired' => 'Kedaluwarsa',
            'refunded' => 'Dikembalikan',
            default => $this->status,
        };
    }
}
