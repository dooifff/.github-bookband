<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreOpeningHourRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'hours' => ['required', 'array', 'min:7', 'max:7'],
            'hours.*.day_of_week' => ['required', 'integer', 'between:0,6'],
            'hours.*.open_time' => ['required_if:hours.*.is_closed,false', 'nullable', 'date_format:H:i'],
            'hours.*.close_time' => ['required_if:hours.*.is_closed,false', 'nullable', 'date_format:H:i', 'after:hours.*.open_time'],
            'hours.*.is_closed' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'hours.required' => 'Jam operasional wajib diisi',
            'hours.array' => 'Format jam operasional tidak valid',
            'hours.min' => 'Jam operasional harus 7 hari',
            'hours.*.day_of_week.required' => 'Hari wajib diisi',
            'hours.*.day_of_week.between' => 'Hari harus antara 0 (Minggu) dan 6 (Sabtu)',
            'hours.*.open_time.required_if' => 'Jam buka wajib diisi jika studio buka',
            'hours.*.close_time.required_if' => 'Jam tutup wajib diisi jika studio buka',
            'hours.*.close_time.after' => 'Jam tutup harus setelah jam buka',
        ];
    }
}
