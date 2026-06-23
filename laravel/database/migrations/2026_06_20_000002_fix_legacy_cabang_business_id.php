KONFIRMASI: Data di database SUDAH BENAR untuk user Frada Tambunan (id=37):
role = kepala_cabang, cabang_id = 42, status = aktif

Jadi bug BUKAN di database. Fokuskan investigasi ke:

1. Endpoint Laravel yang dipanggil setelah login Google (cek response API-nya langsung — pakai Thunder Client atau log response) — pastikan field `role` dan `cabang_id` ini benar-benar ikut dikirim ke Flutter, tidak hilang di tengah jalan (cek Resource class atau response formatting).

2. Logic routing di Flutter setelah login — cari kondisi PERSIS yang dipakai untuk decide "tampilkan onboarding" vs "langsung ke dashboard". Kalau ternyata kondisinya cek `user.business_id == null`, INI BUG-NYA — karena Kepala Cabang memang tidak dan tidak akan pernah punya business_id sendiri (dia terhubung lewat cabang_id, bukan business_id). Ganti logic-nya jadi cek `user.role` saja:
   - role == null → onboarding
   - role == 'owner' → Dashboard Owner
   - role == 'kepala_cabang' → Dashboard Kepala Cabang

Laporkan baris kode persis yang jadi penyebabnya sebelum fix.<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * DATA FIX: Cabang dengan business_id=NULL (legacy data).
     * Cabang id=39 "cabang 1" (Piayu) dibuat saat kolom business_id belum ada.
     * Dari investigasi: cabang ini milik business_id=8 (kasentra19@gmail.com).
     */
    public function up(): void
    {
        $orphans = DB::table('cabangs')->whereNull('business_id')->get(['id', 'nama']);

        if ($orphans->isEmpty()) {
            return;
        }

        // Business terlama (id terkecil) = Kasentra (business_id=8, owner_id=31)
        $firstBusiness = DB::table('businesses')->orderBy('id')->first();

        if (!$firstBusiness) {
            return;
        }

        foreach ($orphans as $cabang) {
            DB::table('cabangs')
                ->where('id', $cabang->id)
                ->update(['business_id' => $firstBusiness->id]);
        }
    }

    public function down(): void
    {
        DB::table('cabangs')
            ->where('id', 39)
            ->update(['business_id' => null]);
    }
};
