<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRoomRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:1000'],
            'capacity' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'price_per_hour' => ['sometimes', 'numeric', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.max' => 'Nama ruangan maksimal 100 karakter',
            'capacity.min' => 'Kapasitas minimal 1 orang',
            'capacity.max' => 'Kapasitas maksimal 100 orang',
            'price_per_hour.min' => 'Harga per jam minimal 0',
        ];
    }
}
