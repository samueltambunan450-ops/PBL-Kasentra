<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Cabang extends Model
{
    use HasFactory;

    protected $table = 'cabangs';

    protected $fillable = [
        'nama',
        'alamat',
        'modal_awal',
        'business_id',
        'jam_buka',
        'jam_tutup',
    ];

    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'cabang_id');
    }

    public function kategoris(): HasMany
    {
        return $this->hasMany(Kategori::class, 'cabang_id');
    }

    public function transaksis(): HasMany
    {
        return $this->hasMany(Transaksi::class, 'cabang_id');
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class, 'business_id');
    }

    public function isOpen(): bool
    {
        if (!$this->jam_buka || !$this->jam_tutup) {
            return true;
        }

        $now = now()->format('H:i:s');
        return $now >= $this->jam_buka && $now <= $this->jam_tutup;
    }
}