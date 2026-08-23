<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreEquipmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'room_id' => ['nullable', 'exists:studio_rooms,id'],
            'name' => ['required', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:500'],
            'brand' => ['nullable', 'string', 'max:100'],
            'model' => ['nullable', 'string', 'max:100'],
            'image' => ['nullable', 'string', 'max:500'],
            'is_included' => ['sometimes', 'boolean'],
            'additional_price' => ['sometimes', 'numeric', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama equipment wajib diisi',
            'name.max' => 'Nama equipment maksimal 100 karakter',
            'room_id.exists' => 'Ruangan tidak ditemukan',
        ];
    }
}
