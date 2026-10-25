<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fundings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->foreignId('category_id')->constrained()->restrictOnDelete();
            $table->string('title', 150);
            $table->text('description');
            $table->bigInteger('target_amount');
            $table->string('status', 20)->default('draft');
            $table->timestamps();
            $table->index(['status', 'created_at', 'id']);
            $table->index(['user_id', 'created_at', 'id']);
        });
        DB::statement("ALTER TABLE fundings ADD CONSTRAINT fundings_status_check CHECK (status IN ('draft', 'published'))");
        DB::statement('ALTER TABLE fundings ADD CONSTRAINT fundings_target_check CHECK (target_amount BETWEEN 1 AND 1000000000000)');
        Schema::create('wishlists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('funding_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['user_id', 'funding_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wishlists');
        Schema::dropIfExists('fundings');
    }
};
