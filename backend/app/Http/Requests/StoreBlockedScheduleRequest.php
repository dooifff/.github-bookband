<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBlockedScheduleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'room_id' => ['nullable', 'exists:studio_rooms,id'],
            'date' => ['required', 'date', 'after_or_equal:today'],
            'start_time' => ['required_if:all_day,false', 'nullable', 'date_format:H:i'],
            'end_time' => ['required_if:all_day,false', 'nullable', 'date_format:H:i', 'after:start_time'],
            'all_day' => ['sometimes', 'boolean'],
            'reason' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'date.required' => 'Tanggal wajib diisi',
            'date.date' => 'Format tanggal tidak valid',
            'date.after_or_equal' => 'Tanggal harus hari ini atau setelahnya',
            'start_time.required_if' => 'Jam mulai wajib diisi jika tidak blok sepanjang hari',
            'start_time.date_format' => 'Format jam mulai tidak valid (HH:mm)',
            'end_time.required_if' => 'Jam selesai wajib diisi jika tidak blok sepanjang hari',
            'end_time.after' => 'Jam selesai harus setelah jam mulai',
            'room_id.exists' => 'Ruangan tidak ditemukan',
        ];
    }
}
