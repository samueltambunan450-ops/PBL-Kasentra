<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Tambahkan 'kepala_cabang' ke enum role
        DB::statement("ALTER TABLE users MODIFY role ENUM('owner','karyawan','kepala_cabang','pending') NULL");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE users MODIFY role ENUM('owner','karyawan','pending') NULL");
    }
};
