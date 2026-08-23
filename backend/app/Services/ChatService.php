<?php

namespace App\Services;

use App\Models\ChatRoom;
use App\Models\ChatMessage;
use App\Models\User;
use App\Models\Booking;
use App\Models\Studio;
use Illuminate\Support\Facades\DB;

class ChatService
{
    /**
     * Create or get chat room for a booking
     */
    public function getOrCreateRoom(int $bookingId, int $userId): ChatRoom
    {
        $booking = Booking::with(['studio', 'user'])->findOrFail($bookingId);
        $studio = $booking->studio;

        // Check if user is customer or owner
        $isCustomer = $booking->user_id === $userId;
        $isOwner = $studio->owner_id === $userId;

        if (!$isCustomer && !$isOwner) {
            throw new \Exception('Anda tidak memiliki akses ke chat ini');
        }

        // Find existing room
        $room = ChatRoom::where('booking_id', $bookingId)
            ->where('customer_id', $booking->user_id)
            ->where('owner_id', $studio->owner_id)
            ->first();

        if (!$room) {
            $room = ChatRoom::create([
                'booking_id' => $bookingId,
                'studio_id' => $studio->id,
                'customer_id' => $booking->user_id,
                'owner_id' => $studio->owner_id,
                'status' => 'active',
            ]);
        }

        return $room->load(['customer:id,name,email,avatar', 'owner:id,name,email,avatar', 'studio:id,name']);
    }

    /**
     * Create or get general chat room with studio owner
     */
    public function getOrCreateGeneralRoom(int $studioId, int $userId): ChatRoom
    {
        $studio = Studio::with('owner')->findOrFail($studioId);

        // Check if user is owner
        if ($studio->owner_id === $userId) {
            throw new \Exception('Tidak bisa chat dengan diri sendiri');
        }

        // Find existing general room (no booking)
        $room = ChatRoom::where('studio_id', $studioId)
            ->where('customer_id', $userId)
            ->where('owner_id', $studio->owner_id)
            ->whereNull('booking_id')
            ->first();

        if (!$room) {
            $room = ChatRoom::create([
                'studio_id' => $studioId,
                'customer_id' => $userId,
                'owner_id' => $studio->owner_id,
                'status' => 'active',
            ]);
        }

        return $room->load(['customer:id,name,email,avatar', 'owner:id,name,email,avatar', 'studio:id,name']);
    }

    /**
     * Send a message
     */
    public function sendMessage(int $roomId, int $senderId, string $message, string $type = 'text', ?string $fileUrl = null): ChatMessage
    {
        $room = ChatRoom::findOrFail($roomId);

        // Check if user is part of the room
        if ($room->customer_id !== $senderId && $room->owner_id !== $senderId) {
            throw new \Exception('Anda tidak memiliki akses ke chat ini');
        }

        if ($room->status !== 'active') {
            throw new \Exception('Chat room sudah ditutup');
        }

        DB::beginTransaction();

        try {
            $chatMessage = ChatMessage::create([
                'chat_room_id' => $roomId,
                'sender_id' => $senderId,
                'message' => $message,
                'type' => $type,
                'file_url' => $fileUrl,
            ]);

            // Update last message time
            $room->update(['last_message_at' => now()]);

            DB::commit();

            return $chatMessage->load('sender:id,name,email,avatar');
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Get messages for a room
     */
    public function getMessages(int $roomId, int $userId, int $page = 1, int $limit = 50): array
    {
        $room = ChatRoom::findOrFail($roomId);

        // Check if user is part of the room
        if ($room->customer_id !== $userId && $room->owner_id !== $userId) {
            throw new \Exception('Anda tidak memiliki akses ke chat ini');
        }

        $messages = ChatMessage::where('chat_room_id', $roomId)
            ->with('sender:id,name,email,avatar')
            ->orderBy('created_at', 'desc')
            ->paginate($limit, ['*'], 'page', $page);

        return [
            'messages' => $messages->items(),
            'meta' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ];
    }

    /**
     * Mark messages as read
     */
    public function markAsRead(int $roomId, int $userId): int
    {
        $room = ChatRoom::findOrFail($roomId);

        // Check if user is part of the room
        if ($room->customer_id !== $userId && $room->owner_id !== $userId) {
            throw new \Exception('Anda tidak memiliki akses ke chat ini');
        }

        return ChatMessage::where('chat_room_id', $roomId)
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }

    /**
     * Get user's chat rooms
     */
    public function getUserRooms(int $userId, ?string $role = null): array
    {
        $query = ChatRoom::where(function ($query) use ($userId) {
            $query->where('customer_id', $userId)
                ->orWhere('owner_id', $userId);
        })
        ->with(['customer:id,name,email,avatar', 'owner:id,name,email,avatar', 'studio:id,name'])
        ->withCount('messages')
        ->orderBy('last_message_at', 'desc');

        $rooms = $query->get();

        // Batch load unread counts to avoid N+1
        $roomIds = $rooms->pluck('id');
        $unreadCounts = ChatMessage::whereIn('chat_room_id', $roomIds)
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->selectRaw('chat_room_id, COUNT(*) as count')
            ->groupBy('chat_room_id')
            ->pluck('count', 'chat_room_id');

        $rooms = $rooms->map(function ($room) use ($unreadCounts) {
            $room->unread_count = $unreadCounts->get($room->id, 0);
            return $room;
        });

        return $rooms->toArray();
    }

    /**
     * Get unread count for user
     */
    public function getUnreadCount(int $userId): int
    {
        $roomIds = ChatRoom::where('customer_id', $userId)
            ->orWhere('owner_id', $userId)
            ->pluck('id');

        return ChatMessage::whereIn('chat_room_id', $roomIds)
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->count();
    }

    /**
     * Close chat room
     */
    public function closeRoom(int $roomId, int $userId): bool
    {
        $room = ChatRoom::findOrFail($roomId);

        // Check if user is part of the room
        if ($room->customer_id !== $userId && $room->owner_id !== $userId) {
            throw new \Exception('Anda tidak memiliki akses ke chat ini');
        }

        return $room->update(['status' => 'closed']);
    }
}
