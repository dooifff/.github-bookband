<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ApiResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return parent::toArray($request);
    }

    /**
     * Wrap resource with standard response format
     */
    public static function wrap($resource, string $message = 'Success', array $meta = [])
    {
        $response = [
            'success' => true,
            'message' => $message,
            'data' => $resource,
        ];

        if (!empty($meta)) {
            $response['meta'] = $meta;
        }

        return $response;
    }
}
