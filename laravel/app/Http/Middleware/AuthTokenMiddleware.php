<?php

namespace App\Http\Middleware;

use App\Models\ApiToken;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthTokenMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->header('Authorization', '');
        if (!str_starts_with($header, 'Bearer ')) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $plainToken = substr($header, 7);
        $hashed = hash('sha256', $plainToken);

        $token = ApiToken::with('user')
            ->where('token', $hashed)
            ->first();

        if (!$token || ($token->expires_at && $token->expires_at->isPast())) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $token->forceFill(['last_used_at' => now()])->save();
        $request->attributes->set('authUser', $token->user);

        return $next($request);
    }
}
