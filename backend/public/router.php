<?php
/**
 * StudioBook - PHP Router for Hostinger Shared Hosting
 * 
 * File ini handles SEMUA request masuk:
 * - /api/*  → Laravel backend (index.php)
 * - Static files → serve langsung
 * - Sisanya → React SPA (index.html)
 * 
 * Upload ke: public_html/backend/public/router.php
 * Di .htaccess root, tambahkan: RewriteRule ^ backend/public/router.php [L,QSA]
 */

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// ============================================
// 1. API Routes → Laravel
// ============================================
if (strpos($uri, '/api/') === 0 || $uri === '/api') {
    // Set correct SCRIPT_NAME for Laravel
    $_SERVER['SCRIPT_NAME'] = '/backend/public/index.php';
    
    require __DIR__ . '/index.php';
    exit;
}

// ============================================
// 2. Up endpoint → Laravel (health check)
// ============================================
if ($uri === '/up') {
    $_SERVER['SCRIPT_NAME'] = '/backend/public/index.php';
    $_SERVER['REQUEST_URI'] = '/up';
    require __DIR__ . '/index.php';
    exit;
}

// ============================================
// 3. Static files → serve langsung
// ============================================
$staticFile = __DIR__ . $uri;
// Strip query string from file path
$staticFile = strtok($staticFile, '?');

if (is_file($staticFile) && is_readable($staticFile)) {
    // Set correct MIME types
    $ext = strtolower(pathinfo($staticFile, PATHINFO_EXTENSION));
    $mimeTypes = [
        'html' => 'text/html',
        'css'  => 'text/css',
        'js'   => 'application/javascript',
        'json' => 'application/json',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif'  => 'image/gif',
        'svg'  => 'image/svg+xml',
        'ico'  => 'image/x-icon',
        'woff' => 'font/woff',
        'woff2'=> 'font/woff2',
        'ttf'  => 'font/ttf',
        'eot'  => 'application/vnd.ms-fontobject',
        'map'  => 'application/json',
        'webp' => 'image/webp',
        'avif' => 'image/avif',
        'mp4'  => 'video/mp4',
        'webm' => 'video/webm',
        'pdf'  => 'application/pdf',
        'txt'  => 'text/plain',
        'xml'  => 'application/xml',
    ];
    
    $mime = $mimeTypes[$ext] ?? mime_content_type($staticFile) ?: 'application/octet-stream';
    
    header('Content-Type: ' . $mime);
    
    // Cache static assets aggressively
    if (in_array($ext, ['js', 'css', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'woff', 'woff2', 'ttf', 'eot', 'webp', 'avif'])) {
        header('Cache-Control: public, max-age=31536000, immutable');
    }
    
    readfile($staticFile);
    exit;
}

// ============================================
// 4. Everything else → React SPA (index.html)
// ============================================
$spaFile = __DIR__ . '/index.html';
if (is_file($spaFile)) {
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-cache, no-store, must-revalidate');
    readfile($spaFile);
    exit;
}

// ============================================
// 5. Fallback: 404
// ============================================
http_response_code(404);
header('Content-Type: application/json');
echo json_encode([
    'success' => false,
    'message' => 'Not Found',
    'path' => $uri,
]);
exit;
