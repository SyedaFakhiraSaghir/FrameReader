/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '3000',
        pathname: '/uploads/**',
      },
      {
        protocol: 'http',
        hostname: '127.0.0.1',
        port: '3000',
        pathname: '/uploads/**',
      },
    ],
    formats: ['image/avif', 'image/webp'],
  },
  // Moved from experimental to root level
  serverExternalPackages: ['sharp', 'canvas'],
  
  // Turbopack configuration (Next.js 16+)
  turbopack: {
    // Optional: configure Turbopack specific settings
    resolveAlias: {
      // Add any aliases if needed
    },
  },
  
  // Webpack fallback for compatibility
  webpack: (config, { isServer }) => {
    // If you have specific webpack configs, they go here
    // But for Next.js 16, you might want to use turbopack instead
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    return config;
  },
};

module.exports = nextConfig;