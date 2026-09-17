import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/proxy/:path*',
        destination: 'http://140.238.224.196:8080/:path*',
      },
    ];
  },
};

export default nextConfig;
