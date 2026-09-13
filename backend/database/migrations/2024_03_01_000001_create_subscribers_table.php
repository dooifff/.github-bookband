<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscribers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('studio_id')->constrained('studios')->onDelete('cascade');
            $table->string('status')->default('pending'); // pending, active, rejected
            $table->timestamp('subscribed_at')->useCurrent();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->string('rejected_reason')->nullable();
            $table->string('assigned_promo_code')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['user_id', 'studio_id']);
            $table->index('status');
            $table->index('studio_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscribers');
    }
};
