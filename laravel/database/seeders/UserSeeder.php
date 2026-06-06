<?php

namespace Database\Seeders;

use App\Models\Cabang;
use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $ownerEmail = env('OWNER_EMAIL', 'owner@kasentra.com');
        $firstCabang = Cabang::query()->orderBy('id')->first();

        User::updateOrCreate(
            ['email' => $ownerEmail],
            [
                'name' => 'Owner Kasentra',
                'role' => 'owner',
                'password' => bcrypt('password'),
                'cabang_id' => null,
            ],
        );

        if ($firstCabang) {
            User::updateOrCreate(
                ['email' => 'karyawan@kasentra.com'],
                [
                    'name' => 'Karyawan Demo',
                    'role' => 'karyawan',
                    'password' => bcrypt('password'),
                    'cabang_id' => $firstCabang->id,
                ],
            );
        }
    }
}
