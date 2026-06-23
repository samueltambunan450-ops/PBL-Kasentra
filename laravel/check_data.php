<?php
require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== USER KEPALA CABANG ===\n";
$user = App\Models\User::where('role', 'kepala_cabang')->first();
if ($user) {
    echo "ID: " . $user->id . "\n";
    echo "Nama: " . $user->name . "\n";
    echo "Email: " . $user->email . "\n";
    echo "Cabang ID: " . $user->cabang_id . "\n";
    if ($user->cabang) {
        echo "Cabang Nama: " . $user->cabang->nama . "\n";
    }
} else {
    echo "Tidak ada Kepala Cabang\n";
}

echo "\n=== TRANSAKSI PENGELUARAN HARI INI (22 Jun 2026) ===\n";
if ($user && $user->cabang_id) {
    $tanggalHariIni = now('Asia/Jakarta')->toDateString();
    echo "Tanggal yang dicek: " . $tanggalHariIni . "\n";
    echo "Timezone: Asia/Jakarta\n";
    
    $transaksis = App\Models\Transaksi::where('cabang_id', $user->cabang_id)
        ->where('jenis', 'pengeluaran')
        ->get();
    
    echo "\nSemua transaksi pengeluaran di cabang {$user->cabang_id}:\n";
    foreach ($transaksis as $t) {
        echo "- ID: {$t->id}, Tanggal: {$t->tanggal}, Nominal: {$t->nominal}, Kategori: {$t->kategori_id}, Jenis: {$t->jenis}\n";
    }
    
    echo "\nTransaksi pengeluaran HARI INI ({$tanggalHariIni}):\n";
    $transaksiHariIni = App\Models\Transaksi::where('cabang_id', $user->cabang_id)
        ->where('jenis', 'pengeluaran')
        ->whereDate('tanggal', $tanggalHariIni)
        ->get();
    
    if ($transaksiHariIni->count() > 0) {
        foreach ($transaksiHariIni as $t) {
            echo "- ID: {$t->id}, Tanggal: {$t->tanggal}, Nominal: {$t->nominal}, Kategori ID: {$t->kategori_id}, Jenis: {$t->jenis}\n";
        }
        echo "\nHASIL: Ada " . $transaksiHariIni->count() . " pengeluaran hari ini\n";
    } else {
        echo "TIDAK ADA pengeluaran hari ini\n";
    }
    
    echo "\n=== EXISTS CHECK ===\n";
    $exists = App\Models\Transaksi::where('cabang_id', $user->cabang_id)
        ->where('jenis', 'pengeluaran')
        ->whereDate('tanggal', $tanggalHariIni)
        ->exists();
    echo "Query exists() result: " . ($exists ? 'TRUE' : 'FALSE') . "\n";
}
