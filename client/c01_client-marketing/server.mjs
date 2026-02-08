import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();

// Read app.json for port configuration
const appConfig = JSON.parse(readFileSync(join(__dirname, 'config/app.json'), 'utf8'));
const PORT = process.env.PORT || appConfig.ports.frontend;

// Serve static files with explicit content types
app.use(express.static(__dirname, {
  setHeaders: (res, path) => {
    if (path.endsWith('.html')) {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
    } else if (path.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
    } else if (path.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css; charset=utf-8');
    } else if (path.endsWith('.dmg')) {
      res.setHeader('Content-Type', 'application/x-apple-diskimage');
      res.setHeader('Content-Disposition', 'attachment; filename="aiprivatesearch.dmg"');
    }
  }
}));

// Serve main page
app.get('/', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.sendFile(join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`AIPrivateSearch Marketing Client running on http://localhost:${PORT}`);
});