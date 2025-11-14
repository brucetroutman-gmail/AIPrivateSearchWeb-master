# PM2 Commands for AIPrivateSearch Marketing Website

## Start Application
```bash
pm2 start ecosystem.config.js
```

## Stop Application
```bash
pm2 stop ecosystem.config.js
```

## Restart Application
```bash
pm2 restart ecosystem.config.js
```

## Delete Application
```bash
pm2 delete ecosystem.config.js
```

## Monitor Applications
```bash
pm2 monit
```

## View Logs
```bash
# All logs
pm2 logs

# Frontend logs only
pm2 logs aiprivatesearch-frontend

# Backend logs only
pm2 logs aiprivatesearch-backend
```

## Application Status
```bash
pm2 status
```

## Save PM2 Configuration (Auto-start on boot)
```bash
pm2 save
pm2 startup
```

## Application URLs
- Frontend: http://localhost:56301
- Backend API: http://localhost:56302