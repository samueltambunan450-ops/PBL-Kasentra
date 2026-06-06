<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsApiMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $headers = [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
            'Access-Control-Allow-Headers' => 'Authorization, Content-Type, Accept, X-Requested-With',
            'Access-Control-Max-Age' => '86400',
        ];

        // Tangani preflight lebih awal agar tidak mentok 404/401.
        if ($request->getMethod() === 'OPTIONS') {
            $response = response('', 204);
            foreach ($headers as $k => $v) {
                $response->headers->set($k, $v);
            }

            return $response;
        }

        $response = $next($request);
        foreach ($headers as $k => $v) {
            $response->headers->set($k, $v);
        }

        return $response;
    }
}

