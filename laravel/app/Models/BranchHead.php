<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class BranchHead extends Model
{
    use HasFactory;

    protected $table = 'branch_heads';

    protected $fillable = [
        'branch_id',
        'user_id',
        'nama',
        'no_hp',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Cabang::class, 'branch_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'branch_head_id');
    }

    public function invitation(): HasOne
    {
        return $this->hasOne(Invitation::class, 'branch_head_id');
    }
}
