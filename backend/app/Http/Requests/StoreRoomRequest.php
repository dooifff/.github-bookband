<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRoomRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:1000'],
            'capacity' => ['required', 'integer', 'min:1', 'max:100'],
            'price_per_hour' => ['required', 'numeric', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama ruangan wajib diisi',
            'name.max' => 'Nama ruangan maksimal 100 karakter',
            'capacity.required' => 'Kapasitas wajib diisi',
            'capacity.min' => 'Kapasitas minimal 1 orang',
            'capacity.max' => 'Kapasitas maksimal 100 orang',
            'price_per_hour.required' => 'Harga per jam wajib diisi',
            'price_per_hour.min' => 'Harga per jam minimal 0',
        ];
    }
}
