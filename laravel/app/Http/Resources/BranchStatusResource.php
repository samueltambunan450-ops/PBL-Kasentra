<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BranchStatusResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        /** @var \App\Models\Cabang $this */
        $activeBranchHead = $this->whenLoaded('activeBranchHead', fn() => $this->activeBranchHead);
        $allBranchHeads   = $this->whenLoaded('branchHeads', fn() => $this->branchHeads);

        return [
            'id'                   => $this->id,
            'nama_cabang'          => $this->nama,
            'alamat'               => $this->alamat,
            'has_active_head'      => $activeBranchHead !== null,
            'active_branch_head'   => $activeBranchHead
                ? [
                    'id'      => $activeBranchHead->id,
                    'nama'    => $activeBranchHead->nama,
                    'no_hp'   => $activeBranchHead->no_hp,
                    'user_id' => $activeBranchHead->user_id,
                ]
                : null,
            'total_branch_heads'   => is_countable($allBranchHeads) ? count($allBranchHeads) : 0,
        ];
    }
}
