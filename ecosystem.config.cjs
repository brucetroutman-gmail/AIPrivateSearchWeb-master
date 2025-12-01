module.exports = {
  apps: [
    {
      name: 'aipsweb-c56301',
      script: './client/c01_client-marketing/server.mjs',
      cwd: '/webs/AIPrivateSearch/repo/aiprivatesearchweb',
      env: {
        PORT: 56301,
        NODE_ENV: 'production'
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 5,
      min_uptime: '10s',
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend-combined.log',
      time: true
    },
    {
      name: 'aipsweb-s56302',
      script: './server/s01_server-marketing/server.mjs',
      cwd: '/webs/AIPrivateSearch/repo/aiprivatesearchweb',
      env: {
        PORT: 56302,
        NODE_ENV: 'production'
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 5,
      min_uptime: '10s',
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true
    }
  ]
};