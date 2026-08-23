<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('favorites', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->timestamps();

            // Indexes
            $table->unique(['user_id', 'studio_id']);
            $table->index('user_id');
            $table->index('studio_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('favorites');
    }
};
