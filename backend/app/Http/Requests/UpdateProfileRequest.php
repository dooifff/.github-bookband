<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = Auth::id();
        
        return [
            'name' => ['sometimes', 'string', 'max:100'],
            'email' => ['sometimes', 'string', 'email', 'max:255', Rule::unique('users')->ignore($userId)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'avatar' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.max' => 'Nama maksimal 100 karakter',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah digunakan oleh pengguna lain',
        ];
    }
}
