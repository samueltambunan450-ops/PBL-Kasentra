<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Set user_id NULL pada transaksi lama menjadi owner_id dari business terkait.
     * Asumsi: transaksi lama (sebelum ada tracking pembuat) diinput manual oleh Owner.
     */
    public function up(): void
    {
        // Ambil semua transaksi yang user_id-nya NULL
        $transaksiNull = DB::table('transaksis')
            ->whereNull('user_id')
            ->get(['id', 'cabang_id']);

        $updated = 0;

        foreach ($transaksiNull as $transaksi) {
            // Cari owner dari cabang ini via business
            $owner = DB::table('cabangs')
                ->join('businesses', 'cabangs.business_id', '=', 'businesses.id')
                ->where('cabangs.id', $transaksi->cabang_id)
                ->value('businesses.owner_id');

            if ($owner) {
                DB::table('transaksis')
                    ->where('id', $transaksi->id)
                    ->update(['user_id' => $owner]);
                $updated++;
            }
            // Jika owner tidak ditemukan (data orphan), biarkan NULL
        }

        // Log hasil untuk informasi
        if ($updated > 0) {
            echo "✅ Fixed $updated transaksi lama dengan user_id NULL → diset ke owner terkait\n";
        }

        $remaining = DB::table('transaksis')->whereNull('user_id')->count();
        if ($remaining > 0) {
            echo "⚠️  Masih ada $remaining transaksi dengan user_id NULL (data orphan, tidak bisa ditentukan owner-nya)\n";
        }
    }

    public function down(): void
    {
        // Tidak perlu rollback karena kita tidak mengubah struktur tabel,
        // hanya memperbaiki data yang sudah ada
    }
};
