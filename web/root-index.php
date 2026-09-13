<?php
/**
 * ============================================================
 * StudioBook — Root PHP Router for Hostinger
 * ============================================================
 * 
 * File ini MENANGANI SEMUA request masuk.
 * Tidak perlu .htaccess rewrite rules!
 * 
 * Upload ke: public_html/index.php
 * 
 * Cara kerja:
 * - /api/*       → Laravel backend
 * - /up          → Laravel health check  
 * - Static files → serve dari backend/public/
 * - Sisanya      → React SPA (index.html)
 * ============================================================
 */

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$documentRoot = __DIR__;

// ============================================
// 1. API Routes → Laravel
// ============================================
if (strpos($uri, '/api/') === 0 || $uri === '/up') {
    // Set SCRIPT_NAME for Laravel routing
    $_SERVER['SCRIPT_NAME'] = '/index.php';
    
    // Load Laravel from backend/public/index.php
    $laravelIndex = $documentRoot . '/backend/public/index.php';
    if (file_exists($laravelIndex)) {
        require $laravelIndex;
        exit;
    }
    
    // Laravel not found
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Laravel backend not found. Please check deployment.',
    ]);
    exit;
}

// ============================================
// 2. Static files → serve dari backend/public/
// ============================================
$filePath = strtok($documentRoot . '/backend/public' . $uri, '?');

if (is_file($filePath) && is_readable($filePath)) {
    $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
    
    // MIME types
    $mimeTypes = [
        'html' => 'text/html; charset=utf-8',
        'css'  => 'text/css; charset=utf-8',
        'js'   => 'application/javascript; charset=utf-8',
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
        'webp' => 'image/webp',
        'map'  => 'application/json',
    ];
    
    $mime = $mimeTypes[$ext] ?? mime_content_type($filePath) ?: 'application/octet-stream';
    
    header('Content-Type: ' . $mime);
    
    // Cache static assets
    if (in_array($ext, ['js', 'css', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'woff', 'woff2', 'ttf', 'webp'])) {
        header('Cache-Control: public, max-age=604800');
    }
    
    readfile($filePath);
    exit;
}

// ============================================
// 3. SPA Fallback → React App
// ============================================
$spaFile = $documentRoot . '/backend/public/index.html';

if (is_file($spaFile)) {
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-cache, no-store, must-revalidate');
    readfile($spaFile);
    exit;
}

// ============================================
// 4. Nothing found → 404
// ============================================
http_response_code(404);
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head><title>404 Not Found</title></head>
<body>
<h1>404 Not Found</h1>
<p>The page you were looking for could not be found.</p>
<p><a href="/">← Back to Home</a></p>
</body>
</html>
