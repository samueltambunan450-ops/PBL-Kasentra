<?php
require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make('Illuminate\Contracts\Console\Kernel');
$kernel->bootstrap();

echo "=== TEST ENDPOINT /transaksis (index) ===\n\n";

// Get Kepala Cabang user
$user = App\Models\User::where('role', 'kepala_cabang')->first();

if (!$user) {
    echo "ERROR: Tidak ada Kepala Cabang\n";
    exit(1);
}

echo "User yang login:\n";
echo "- ID: {$user->id}\n";
echo "- Nama: {$user->name}\n";
echo "- Role: {$user->role}\n";
echo "- Cabang ID: {$user->cabang_id}\n";
if ($user->cabang) {
    echo "- Cabang Nama: {$user->cabang->nama}\n";
}
echo "\n";

echo "=== SIMULASI QUERY CONTROLLER ===\n";

$query = App\Models\Transaksi::with(['cabang', 'kategori', 'user'])
    ->orderByDesc('tanggal')
    ->orderByDesc('id');

if ($user->role === 'owner') {
    echo "Role: Owner\n";
    $cabangIds = App\Models\Business::where('owner_id', $user->id)
        ->first()
        ?->cabangs()
        ->pluck('id') ?? collect();
    
    echo "Cabang IDs milik owner: " . $cabangIds->join(', ') . "\n";
    $query->whereIn('cabang_id', $cabangIds);
} elseif ($user->role === 'karyawan' || $user->role === 'kepala_cabang') {
    echo "Role: Karyawan/Kepala Cabang\n";
    echo "Filter: WHERE cabang_id = {$user->cabang_id}\n";
    $query->where('cabang_id', $user->cabang_id);
} else {
    echo "Role tidak dikenali\n";
}

echo "\n=== HASIL QUERY ===\n";

$transaksis = $query->get([
    'id', 'cabang_id', 'kategori_id', 'user_id', 'jenis',
    'nominal', 'tanggal', 'keterangan', 'foto_bukti', 'is_modal_kiriman',
]);

echo "Total transaksi: " . $transaksis->count() . "\n\n";

if ($transaksis->count() > 0) {
    echo "Detail transaksi:\n";
    foreach ($transaksis as $t) {
        $kategoriNama = $t->kategori ? $t->kategori->nama : 'NULL';
        $cabangNama = $t->cabang ? $t->cabang->nama : 'NULL';
        echo "- ID: {$t->id}, Tanggal: {$t->tanggal}, Jenis: {$t->jenis}, Nominal: Rp " . number_format($t->nominal, 0, ',', '.') . "\n";
        echo "  Cabang: {$cabangNama} (ID: {$t->cabang_id}), Kategori: {$kategoriNama}, Keterangan: {$t->keterangan}\n";
    }
} else {
    echo "❌ TIDAK ADA transaksi yang dikembalikan!\n";
    echo "\n=== DEBUGGING ===\n";
    echo "Cek semua transaksi di database:\n";
    
    $allTransaksis = App\Models\Transaksi::all();
    echo "Total semua transaksi: " . $allTransaksis->count() . "\n";
    
    if ($allTransaksis->count() > 0) {
        echo "\nTransaksi yang ada:\n";
        foreach ($allTransaksis as $t) {
            echo "- ID: {$t->id}, Cabang ID: {$t->cabang_id}, Jenis: {$t->jenis}, Tanggal: {$t->tanggal}\n";
        }
        
        echo "\n=== CEK MATCH ===\n";
        echo "User cabang_id: {$user->cabang_id}\n";
        echo "Transaksi dengan cabang_id yang match:\n";
        $matching = $allTransaksis->where('cabang_id', $user->cabang_id);
        echo "Count: " . $matching->count() . "\n";
        foreach ($matching as $t) {
            echo "- ID: {$t->id}, Cabang ID: {$t->cabang_id} (MATCH!), Jenis: {$t->jenis}\n";
        }
    }
}

echo "\n=== CEK TIPE DATA ===\n";
echo "user->cabang_id type: " . gettype($user->cabang_id) . "\n";
echo "user->cabang_id value: " . var_export($user->cabang_id, true) . "\n";

if ($transaksis->count() > 0) {
    $first = $transaksis->first();
    echo "transaksi->cabang_id type: " . gettype($first->cabang_id) . "\n";
    echo "transaksi->cabang_id value: " . var_export($first->cabang_id, true) . "\n";
}
