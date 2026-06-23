<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->foreignId('branch_id')
                ->constrained('cabangs')
                ->cascadeOnDelete();
            $table->foreignId('branch_head_id')
                ->constrained('branch_heads')
                ->cascadeOnDelete();
            $table->string('nama');
            $table->string('jabatan');
            $table->decimal('gaji_pokok', 15, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};
