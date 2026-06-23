<?php
require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make('Illuminate\Contracts\Console\Kernel');
$kernel->bootstrap();

echo "=== TEST API ENDPOINT cekPengeluaranHariIni ===\n\n";

// Simulate authenticated user (Kepala Cabang)
$user = App\Models\User::where('role', 'kepala_cabang')->first();

if (!$user) {
    echo "ERROR: Tidak ada Kepala Cabang di database\n";
    exit(1);
}

echo "User yang login:\n";
echo "- ID: {$user->id}\n";
echo "- Nama: {$user->name}\n";
echo "- Role: {$user->role}\n";
echo "- Cabang ID: {$user->cabang_id}\n";
echo "- Cabang Nama: " . ($user->cabang ? $user->cabang->nama : 'NULL') . "\n\n";

// Simulate the controller logic
echo "=== SIMULASI LOGIC CONTROLLER ===\n";

if (!$user->cabang_id) {
    echo "ERROR: User tidak memiliki cabang_id\n";
    exit(1);
}

if ($user->role !== 'karyawan' && $user->role !== 'kepala_cabang') {
    echo "User adalah Owner, return TRUE (bypass validasi)\n";
} else {
    echo "User adalah {$user->role}, cek pengeluaran...\n";
    
    $tanggalHariIni = now('Asia/Jakarta')->toDateString();
    echo "Tanggal yang dicek: {$tanggalHariIni}\n";
    echo "Cabang ID yang dicek: {$user->cabang_id}\n\n";
    
    echo "Query yang dijalankan:\n";
    echo "Transaksi::where('cabang_id', {$user->cabang_id})\n";
    echo "  ->where('jenis', 'pengeluaran')\n";
    echo "  ->whereDate('tanggal', '{$tanggalHariIni}')\n";
    echo "  ->exists()\n\n";
    
    $ada = App\Models\Transaksi::where('cabang_id', $user->cabang_id)
        ->where('jenis', 'pengeluaran')
        ->whereDate('tanggal', $tanggalHariIni)
        ->exists();
    
    echo "Hasil exists(): " . ($ada ? 'TRUE' : 'FALSE') . "\n\n";
    
    echo "Response JSON yang dikirim ke Flutter:\n";
    echo json_encode([
        'success' => true,
        'sudah_ada_pengeluaran' => $ada,
    ], JSON_PRETTY_PRINT) . "\n\n";
    
    if ($ada) {
        echo "✅ SEHARUSNYA: Flutter menerima sudah_ada_pengeluaran = true\n";
        echo "✅ SEHARUSNYA: Warning TIDAK muncul\n";
    } else {
        echo "❌ SEHARUSNYA: Flutter menerima sudah_ada_pengeluaran = false\n";
        echo "❌ SEHARUSNYA: Warning MUNCUL\n";
    }
}

echo "\n=== CEK DATA TRANSAKSI DETAIL ===\n";
$transaksis = App\Models\Transaksi::where('cabang_id', $user->cabang_id)
    ->where('jenis', 'pengeluaran')
    ->orderBy('tanggal', 'desc')
    ->limit(5)
    ->get();

foreach ($transaksis as $t) {
    echo "- ID: {$t->id}, Tanggal: {$t->tanggal}, Nominal: Rp " . number_format($t->nominal, 0, ',', '.') . ", Jenis: {$t->jenis}\n";
    if ($t->kategori) {
        echo "  Kategori: {$t->kategori->nama}\n";
    }
}
