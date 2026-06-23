<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BranchHeadResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'branch_id'   => $this->branch_id,
            'user_id'     => $this->user_id,
            'nama'        => $this->nama,
            'no_hp'       => $this->no_hp,
            'is_active'   => $this->is_active,
            'branch_name' => $this->whenLoaded('branch', fn() => $this->branch->nama),
            'user_email'  => $this->whenLoaded('user', fn() => $this->user?->email),
            'invitation'  => $this->whenLoaded('invitation', function () {
                $inv = $this->invitation;
                if (!$inv) return null;
                return [
                    'code'       => $inv->code,
                    'expires_at' => $inv->expires_at,
                    'is_used'    => $inv->isUsed(),
                    'is_expired' => $inv->isExpired(),
                ];
            }),
            'created_at'  => $this->created_at,
        ];
    }
}
