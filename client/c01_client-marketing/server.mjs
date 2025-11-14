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

// Serve static files
app.use(express.static(__dirname));

// Serve main page
app.get('/', (req, res) => {
  res.sendFile(join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`AIPrivateSearch Marketing Client running on http://localhost:${PORT}`);
});