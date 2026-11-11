<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_active')->default(true)->index();
            $table->foreignId('status_changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('status_changed_at')->nullable();
            $table->text('status_reason')->nullable();
            $table->unsignedBigInteger('status_version')->default(0);
        });
        DB::statement("ALTER TABLE users ADD CONSTRAINT users_admin_active_check CHECK (role <> 'admin' OR is_active)");
        Schema::create('admin_activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_name', 100);
            $table->string('event', 64)->index();
            $table->string('subject_type', 32);
            $table->unsignedBigInteger('subject_id');
            $table->string('subject_label', 254);
            $table->jsonb('before_values')->nullable();
            $table->jsonb('after_values')->nullable();
            $table->text('reason')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['created_at', 'id']);
            $table->index(['actor_id', 'created_at']);
            $table->index(['subject_type', 'subject_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_activity_logs');
        DB::statement('ALTER TABLE users DROP CONSTRAINT users_admin_active_check');
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('status_changed_by');
            $table->dropColumn(['is_active', 'status_changed_at', 'status_reason', 'status_version']);
        });
    }
};
