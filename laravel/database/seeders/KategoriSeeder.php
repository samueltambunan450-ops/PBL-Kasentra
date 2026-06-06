<?php

namespace Database\Seeders;

use App\Models\Kategori;
use Illuminate\Database\Seeder;

class KategoriSeeder extends Seeder
{
    public function run(): void
    {
        $data = [
            ['nama' => 'Penjualan', 'jenis' => 'pemasukan', 'scope' => 'global', 'cabang_id' => null],
            ['nama' => 'Operasional', 'jenis' => 'pengeluaran', 'scope' => 'global', 'cabang_id' => null],
            ['nama' => 'Gaji', 'jenis' => 'pengeluaran', 'scope' => 'global', 'cabang_id' => null],
            ['nama' => 'Bahan Baku', 'jenis' => 'pengeluaran', 'scope' => 'global', 'cabang_id' => null],
        ];

        foreach ($data as $row) {
            Kategori::updateOrCreate(
                [
                    'nama' => $row['nama'],
                    'jenis' => $row['jenis'],
                    'scope' => $row['scope'],
                    'cabang_id' => $row['cabang_id'],
                ],
                $row,
            );
        }
    }
}
