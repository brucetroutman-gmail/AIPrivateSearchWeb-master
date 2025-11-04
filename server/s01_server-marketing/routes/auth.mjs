import express from 'express';
import { v4 as uuidv4 } from 'uuid';

const router = express.Router();

// In-memory user store (replace with database in production)
const users = new Map();
const sessions = new Map();

const SESSION_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours

// Register endpoint
router.post('/register', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' });
    }
    
    if (users.has(email)) {
      return res.status(409).json({ error: 'User already exists' });
    }
    
    const userId = uuidv4();
    
    users.set(email, {
      id: userId,
      email,
      password, // In production, hash this
      name,
      createdAt: new Date(),
      subscriptionTier: 'standard',
      userRole: 'admin'
    });
    
    res.json({ success: true, message: 'User registered successfully' });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    const user = users.get(email);
    if (!user || user.password !== password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const sessionId = uuidv4();
    const expiresAt = new Date(Date.now() + SESSION_EXPIRY);
    
    sessions.set(sessionId, {
      userId: user.id,
      email: user.email,
      expiresAt
    });
    
    res.json({
      success: true,
      sessionId,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        subscriptionTier: user.subscriptionTier,
        userRole: user.userRole
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get current user endpoint
router.get('/me', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const sessionId = authHeader.substring(7);
  const session = sessions.get(sessionId);
  
  if (!session || session.expiresAt < new Date()) {
    sessions.delete(sessionId);
    return res.status(401).json({ error: 'Invalid or expired session' });
  }
  
  const user = Array.from(users.values()).find(u => u.id === session.userId);
  if (!user) {
    return res.status(401).json({ error: 'User not found' });
  }
  
  res.json({
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      subscriptionTier: user.subscriptionTier,
      userRole: user.userRole
    }
  });
});

// Logout endpoint
router.post('/logout', (req, res) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const sessionId = authHeader.substring(7);
    sessions.delete(sessionId);
  }
  
  res.json({ success: true, message: 'Logged out successfully' });
});

export default router;