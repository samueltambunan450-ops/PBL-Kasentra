<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Satu blok saja — tidak boleh ada dua withMiddleware()
        $middleware->alias([
            'cors.api'   => \App\Http\Middleware\CorsMiddleware::class,
            'auth.token' => \App\Http\Middleware\AuthTokenMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Pastikan SEMUA exception di route API dikembalikan sebagai JSON,
        // bukan halaman error HTML. Ini mengatasi raw HTML yang tampil di Flutter.
        $exceptions->shouldRenderJsonWhen(function (Request $request) {
            return $request->is('api/*') || $request->expectsJson();
        });
    })
    ->create();
