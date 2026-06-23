<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transaksi extends Model
{
    use HasFactory;

    protected $table = 'transaksis';

    protected $fillable = [
        'cabang_id',
        'kategori_id',
        'user_id',
        'jenis',
        'nominal',
        'tanggal',
        'keterangan',
        'foto_bukti',
        'is_modal_kiriman',
    ];

    protected $casts = [
        'tanggal' => 'date:Y-m-d',
        'nominal' => 'integer',
        'is_modal_kiriman' => 'boolean',
    ];

    protected $appends = [
        'created_by_name',
    ];

    public function cabang(): BelongsTo
    {
        return $this->belongsTo(Cabang::class, 'cabang_id');
    }

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Accessor untuk nama pembuat transaksi.
     * Mengembalikan nama user atau "Tidak diketahui" jika user_id NULL.
     */
    public function getCreatedByNameAttribute(): string
    {
        return $this->user?->name ?? 'Tidak diketahui';
    }
}
