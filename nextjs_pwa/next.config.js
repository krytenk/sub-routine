/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Single-threaded WebAssembly: Omit strict COOP/COEP isolation headers so game can be hosted
  // on external web portals, itch.io, Newgrounds, and mobile webviews without breaking.
  async headers() {
    return [
      {
        source: '/game/:all*(pck|wasm)',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
          {
            key: 'Cross-Origin-Resource-Policy',
            value: 'cross-origin',
          },
        ],
      },
      {
        source: '/sw.js',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, must-revalidate',
          },
          {
            key: 'Service-Worker-Allowed',
            value: '/',
          },
        ],
      },
    ];
  },
  webpack: (config) => {
    config.experiments = {
      ...config.experiments,
      asyncWebAssembly: true,
      layers: true,
    };
    return config;
  },
};

module.exports = nextConfig;
