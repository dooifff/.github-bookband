<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'studio_id' => 'required|exists:studios,id',
            'room_id' => 'required|exists:studio_rooms,id',
            'band_id' => 'nullable|exists:bands,id',
            'date' => 'required|date|after_or_equal:today',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'promo_code' => 'nullable|string|max:50',
            'notes' => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'studio_id.required' => 'Studio harus dipilih',
            'studio_id.exists' => 'Studio tidak ditemukan',
            'room_id.required' => 'Ruangan harus dipilih',
            'room_id.exists' => 'Ruangan tidak ditemukan',
            'date.required' => 'Tanggal booking harus diisi',
            'date.date' => 'Format tanggal tidak valid',
            'date.after_or_equal' => 'Tanggal booking tidak boleh di masa lalu',
            'start_time.required' => 'Jam mulai harus diisi',
            'start_time.date_format' => 'Format jam mulai tidak valid (HH:mm)',
            'end_time.required' => 'Jam selesai harus diisi',
            'end_time.after' => 'Jam selesai harus setelah jam mulai',
            'promo_code.max' => 'Kode promo maksimal 50 karakter',
            'notes.max' => 'Catatan maksimal 500 karakter',
        ];
    }
}
