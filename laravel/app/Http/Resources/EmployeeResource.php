<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmployeeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'branch_id'      => $this->branch_id,
            'branch_head_id' => $this->branch_head_id,
            'nama'           => $this->nama,
            'jabatan'        => $this->jabatan,
            'gaji_pokok'     => (float) $this->gaji_pokok,
            'status'         => $this->status,
            'branch_name'    => $this->whenLoaded('branch', fn() => $this->branch->nama),
            'created_at'     => $this->created_at,
        ];
    }
}
