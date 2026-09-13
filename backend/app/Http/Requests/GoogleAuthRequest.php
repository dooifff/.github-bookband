<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GoogleAuthRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_token' => ['required', 'string'],
            'role' => ['nullable', 'string', 'in:customer,owner'],
        ];
    }

    public function messages(): array
    {
        return [
            'id_token.required' => 'Token Google wajib dikirim',
            'role.in' => 'Role hanya boleh customer atau owner',
        ];
    }
}
