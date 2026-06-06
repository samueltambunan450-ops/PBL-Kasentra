<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use App\Models\Invitation;
use App\Models\Business;
use App\Models\Cabang;
use Illuminate\Http\Client\RequestException;
use Illuminate\Database\QueryException as DbQueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function google(Request $request): JsonResponse
    {
        // Ensure raw JSON body is parsed in case middleware didn't populate json()
        $parsed = $request->json()->all();
        if (empty($parsed)) {
            $raw = $request->getContent();
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                $request->merge($decoded);
            }
        }

        $data = $request->validate([
            'google_uid' => ['required', 'string'],
            'email'      => ['required', 'email'],
            'name'       => ['nullable', 'string'],
        ]);

        $name = $data['name'] ?: Str::before($data['email'], '@');

        $user = User::query()
            ->where('google_uid', $data['google_uid'])
            ->orWhere('email', $data['email'])
            ->first();

        if (!$user) {
            try {
                $user = User::create([
                    'name'       => $name,
                    'email'      => $data['email'],
                    'google_uid' => $data['google_uid'],
                    'role'       => 'pending',
                ]);
            } catch (DbQueryException $e) {
                // Fallback if DB enum doesn't accept 'pending'
                $user = User::create([
                    'name'       => $name,
                    'email'      => $data['email'],
                    'google_uid' => $data['google_uid'],
                    'role'       => 'karyawan',
                ]);
            }
        } else {
            $user->update([
                'name'       => $name,
                'google_uid' => $data['google_uid'],
            ]);
        }

        $plainToken = Str::random(60);
        ApiToken::query()->create([
            'user_id'    => $user->id,
            'token'      => hash('sha256', $plainToken),
            'expires_at' => now()->addDays(14),
        ]);

        return response()->json([
            'token' => $plainToken,
            'user'  => $user->load('cabang'),
        ])->header('Access-Control-Allow-Origin', '*');
    }

    public function logout(Request $request): JsonResponse
    {
        $header = $request->header('Authorization', '');
        $plainToken = str_starts_with($header, 'Bearer ') ? substr($header, 7) : '';
        if ($plainToken !== '') {
            ApiToken::query()->where('token', hash('sha256', $plainToken))->delete();
        }

        return response()->json(['message' => 'Logout berhasil']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $request->attributes->get('authUser')?->load('cabang'),
        ]);
    }

    public function validateInvitation(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string'],
        ]);

        $user = $request->attributes->get('authUser');
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        if ($user->role !== 'pending') {
            return response()->json(['message' => 'Pengguna sudah terdaftar sebagai role lain'], 403);
        }

        $invitation = Invitation::query()
            ->where('code', trim($data['code']))
            ->first();

        if (!$invitation || $invitation->used_at || ($invitation->expires_at && $invitation->expires_at->isPast())) {
            return response()->json(['message' => 'Kode salah atau kadaluarsa'], 422);
        }

        $user->role = 'karyawan';
        $user->cabang_id = $invitation->cabang_id;
        $user->save();

        $invitation->used_at = now();
        $invitation->save();

        return response()->json([
            'message' => 'Berhasil bergabung sebagai karyawan',
            'user' => $user->load('cabang'),
        ]);
    }

    public function setupBusiness(Request $request): JsonResponse
    {
        $data = $request->validate([
            'business_name' => ['required', 'string'],
            'business_type' => ['required', 'string'],
            'branch_name' => ['required', 'string'],
        ]);

        $user = $request->attributes->get('authUser');
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        if ($user->role !== 'pending') {
            return response()->json(['message' => 'Pengguna sudah terdaftar sebagai role lain'], 403);
        }

        $business = Business::query()->create([
            'owner_id' => $user->id,
            'nama' => $data['business_name'],
            'jenis' => $data['business_type'],
        ]);

        Cabang::query()->create([
            'nama' => $data['branch_name'],
            'alamat' => '',
            'modal_awal' => 0,
            'business_id' => $business->id,
        ]);

        $user->role = 'owner';
        $user->cabang_id = null;
        $user->save();

        return response()->json([
            'message' => 'Usaha berhasil dibuat',
            'user' => $user->load('cabang'),
        ]);
    }

    public function generateInvitation(Request $request): JsonResponse
    {
        $data = $request->validate([
            'cabang_id' => ['required', 'integer', 'exists:cabangs,id'],
        ]);

        $user = $request->attributes->get('authUser');
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        if ($user->role !== 'owner') {
            return response()->json(['message' => 'Hanya owner yang dapat membuat kode undangan'], 403);
        }

        $code = $this->generateUniqueInvitationCode();
        $invitation = Invitation::query()->create([
            'owner_id' => $user->id,
            'cabang_id' => $data['cabang_id'],
            'code' => $code,
            'expires_at' => now()->addDay(),
        ]);

        return response()->json([
            'code' => $invitation->code,
            'expires_at' => $invitation->expires_at,
        ]);
    }

    private function generateUniqueInvitationCode(): string
    {
        do {
            $code = strtoupper(Str::random(8));
        } while (Invitation::query()->where('code', $code)->exists());

        return $code;
    }
}
