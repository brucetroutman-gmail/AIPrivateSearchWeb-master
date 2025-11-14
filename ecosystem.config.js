module.exports = {
  apps: [
    {
      name: 'aiprivatesearch-frontend',
      script: 'client/c01_client-marketing/server.mjs',
      env: {
        PORT: 56301,
        NODE_ENV: 'production'
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend-combined.log',
      time: true
    },
    {
      name: 'aiprivatesearch-backend',
      script: 'server/s01_server-marketing/server.mjs',
      env: {
        PORT: 56302,
        NODE_ENV: 'production'
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true
    }
  ]
};