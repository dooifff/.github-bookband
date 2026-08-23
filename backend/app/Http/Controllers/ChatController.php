<?php

namespace App\Http\Controllers;

use App\Services\ChatService;
use App\Models\ChatRoom;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ChatController extends Controller
{
    public function __construct(
        private ChatService $chatService
    ) {}

    /**
     * Get user's chat rooms
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $rooms = $this->chatService->getUserRooms($user->id, $user->role);

        return response()->json([
            'success' => true,
            'data' => $rooms,
        ]);
    }

    /**
     * Create or get chat room for booking
     */
    public function createRoom(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'booking_id' => 'required|exists:bookings,id',
        ]);

        try {
            $room = $this->chatService->getOrCreateRoom(
                $request->booking_id,
                $user->id
            );

            return response()->json([
                'success' => true,
                'data' => $room,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 403);
        }
    }

    /**
     * Create or get general chat room with studio
     */
    public function createGeneralRoom(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'studio_id' => 'required|exists:studios,id',
        ]);

        try {
            $room = $this->chatService->getOrCreateGeneralRoom(
                $request->studio_id,
                $user->id
            );

            return response()->json([
                'success' => true,
                'data' => $room,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Get messages for a room
     */
    public function messages(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();
        
        $page = $request->get('page', 1);
        $limit = $request->get('limit', 50);

        try {
            $result = $this->chatService->getMessages(
                $roomId,
                $user->id,
                $page,
                $limit
            );

            return response()->json([
                'success' => true,
                'data' => $result['messages'],
                'meta' => $result['meta'],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 403);
        }
    }

    /**
     * Send a message
     */
    public function sendMessage(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'message' => 'required|string|max:1000',
            'type' => 'nullable|in:text,image,file',
            'file_url' => 'nullable|string',
        ]);

        try {
            $message = $this->chatService->sendMessage(
                $roomId,
                $user->id,
                $request->message,
                $request->get('type', 'text'),
                $request->file_url
            );

            return response()->json([
                'success' => true,
                'data' => $message,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Mark messages as read
     */
    public function markAsRead(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        try {
            $count = $this->chatService->markAsRead($roomId, $user->id);

            return response()->json([
                'success' => true,
                'message' => "{$count} pesan ditandai sudah dibaca",
                'data' => [
                    'count' => $count,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 403);
        }
    }

    /**
     * Get unread count
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $count = $this->chatService->getUnreadCount($user->id);

        return response()->json([
            'success' => true,
            'data' => [
                'count' => $count,
            ],
        ]);
    }

    /**
     * Close chat room
     */
    public function close(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        try {
            $this->chatService->closeRoom($roomId, $user->id);

            return response()->json([
                'success' => true,
                'message' => 'Chat berhasil ditutup',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 403);
        }
    }
}
