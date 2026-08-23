<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('studio_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->string('url');
            $table->string('caption')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();

            // Indexes
            $table->index('studio_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('studio_images');
    }
};
