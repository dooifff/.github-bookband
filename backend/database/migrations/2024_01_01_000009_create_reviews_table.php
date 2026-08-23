<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained('bookings')->nullOnDelete();
            $table->unsignedTinyInteger('rating'); // 1-5
            $table->text('comment')->nullable();
            $table->boolean('is_anonymous')->default(false);
            $table->boolean('is_approved')->default(true);
            $table->softDeletes();
            $table->timestamps();

            // Indexes
            $table->index('user_id');
            $table->index('studio_id');
            $table->index('booking_id');
            $table->index('rating');
            $table->unique(['user_id', 'booking_id'], 'unique_review_per_booking');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
