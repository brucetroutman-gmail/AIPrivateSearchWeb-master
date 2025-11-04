import express from 'express';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import authRoutes from './routes/auth.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(join(__dirname, '../../client/c01_client-marketing')));

// CSRF Token endpoint
app.get('/api/csrf-token', (req, res) => {
  const csrfToken = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
  res.json({ csrfToken });
});

// Authentication routes
app.use('/api/auth', authRoutes);

// Serve main pages
app.get('/', (req, res) => {
  res.sendFile(join(__dirname, '../../client/c01_client-marketing/index.html'));
});

app.get('/pricing', (req, res) => {
  res.sendFile(join(__dirname, '../../client/c01_client-marketing/pricing.html'));
});

app.get('/signup', (req, res) => {
  res.sendFile(join(__dirname, '../../client/c01_client-marketing/signup.html'));
});

app.get('/download', (req, res) => {
  res.sendFile(join(__dirname, '../../client/c01_client-marketing/download.html'));
});

// API Routes
app.post('/api/signup', (req, res) => {
  const { firstName, lastName, email, company, industry, plan } = req.body;
  
  console.log('New signup:', { firstName, lastName, email, company, industry, plan });
  
  res.json({ 
    success: true, 
    message: 'Account created successfully!',
    downloadUrl: '/download?registered=true'
  });
});

app.post('/api/contact', (req, res) => {
  const { name, email, subject, message } = req.body;
  
  console.log('Contact form:', { name, email, subject, message });
  
  res.json({ 
    success: true, 
    message: 'Thank you for your message. We\'ll get back to you soon!' 
  });
});

app.listen(PORT, () => {
  console.log(`AIPrivateSearch Marketing Website running on http://localhost:${PORT}`);
});