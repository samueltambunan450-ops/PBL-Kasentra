<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE users MODIFY role ENUM('owner','karyawan','pending') NULL");
        DB::statement("UPDATE users SET role = 'pending' WHERE role IS NULL OR role = ''");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE users MODIFY role ENUM('owner','karyawan') NOT NULL DEFAULT 'karyawan'");
    }
};
