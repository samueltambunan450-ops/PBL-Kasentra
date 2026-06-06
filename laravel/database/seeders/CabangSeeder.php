<?php

namespace Database\Seeders;

use App\Models\Cabang;
use Illuminate\Database\Seeder;

class CabangSeeder extends Seeder
{
    public function run(): void
    {
        $data = [
            [
                'nama' => 'Cabang Pusat',
                'alamat' => 'Jl. Pusat No. 1',
                'modal_awal' => 10000000,
            ],
            [
                'nama' => 'Cabang Selatan',
                'alamat' => 'Jl. Selatan No. 12',
                'modal_awal' => 8000000,
            ],
        ];

        foreach ($data as $row) {
            Cabang::updateOrCreate(
                ['nama' => $row['nama']],
                $row,
            );
        }
    }
}
