#!/usr/bin/env node
/**
 * Standalone PWA HTTP Server for "Sub-Routine"
 * Serves the Next.js PWA shell and single-threaded Godot WebAssembly assets
 * with proper MIME types, Service Worker scopes, and PCK caching headers.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wav': 'audio/wav',
  '.ogg': 'audio/ogg',
  '.glb': 'model/gltf-binary'
};

const server = http.createServer((req, res) => {
  const urlPath = req.url.split('?')[0];
  let filePath = path.join(PUBLIC_DIR, urlPath === '/' ? 'game/index.html' : urlPath);

  // Security check: restrict path traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('403 Forbidden');
    return;
  }

  // Set single-threaded WebAssembly headers (per GDD: no COOP/COEP isolation requirement)
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Cache headers for .pck and .wasm
  if (urlPath.endsWith('.pck') || urlPath.endsWith('.wasm')) {
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
  } else if (urlPath.endsWith('/sw.js')) {
    res.setHeader('Cache-Control', 'public, max-age=0, must-revalidate');
    res.setHeader('Service-Worker-Allowed', '/');
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // Check fallback to index.html
      const fallbackHtml = path.join(PUBLIC_DIR, 'game/index.html');
      fs.readFile(fallbackHtml, (err2, data) => {
        if (err2) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('404 Not Found');
        } else {
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(data);
        }
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[Sub-Routine PWA Server] Running at http://127.0.0.1:${PORT}`);
  console.log(`- Godot WebAssembly: Single-Threaded WASM ready`);
  console.log(`- Service Worker Caching: Active for .pck & .wasm`);
  console.log(`- Target: Android / Linux / Web Portals`);
});
