<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Employee extends Model
{
    use HasFactory;

    protected $table = 'employees';

    protected $fillable = [
        'branch_id',
        'branch_head_id',
        'nama',
        'jabatan',
        'gaji_pokok',
        'status',
    ];

    protected $casts = [
        'gaji_pokok' => 'decimal:2',
    ];

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Cabang::class, 'branch_id');
    }

    public function branchHead(): BelongsTo
    {
        return $this->belongsTo(BranchHead::class, 'branch_head_id');
    }
}
