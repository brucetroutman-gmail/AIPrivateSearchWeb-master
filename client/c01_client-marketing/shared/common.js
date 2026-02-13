// AIPrivateSearch Marketing Website - Common JavaScript
import { DOMSanitizer } from './utils/domSanitizer.js';
import AuthUtils from './utils/authUtils.js';
import './utils/apiConfig.js';

// Simple rate limiting
let messageCallCount = 0;
let lastMessageReset = Date.now();
let promptCallCount = 0;
let lastPromptReset = Date.now();

// User message system with rate limiting
function showUserMessage(message, type = 'info') {
  // Rate limiting - max 10 messages per 30 seconds
  const now = Date.now();
  if (now - lastMessageReset > 30000) {
    messageCallCount = 0;
    lastMessageReset = now;
  }
  if (messageCallCount >= 10) return;
  messageCallCount++;
  
  // Sanitize input using DOMSanitizer
  const sanitizedMessage = DOMSanitizer.sanitizeText(message).substring(0, 200);
  
  const validTypes = ['info', 'success', 'error'];
  const safeType = validTypes.includes(type) ? type : 'info';
  
  let messageEl = document.getElementById('user-message');
  if (!messageEl) {
    messageEl = document.createElement('div');
    messageEl.id = 'user-message';
    messageEl.className = 'user-message';
    document.body.appendChild(messageEl);
  }
  
  messageEl.textContent = sanitizedMessage;
  messageEl.className = `user-message ${safeType}`;
  
  setTimeout(() => {
    if (messageEl && messageEl.parentNode) {
      messageEl.parentNode.removeChild(messageEl);
    }
  }, 3000);
}

// Secure prompt replacement
function securePrompt(message, defaultValue = '') {
  // Rate limiting - max 5 prompts per 60 seconds
  const now = Date.now();
  if (now - lastPromptReset > 60000) {
    promptCallCount = 0;
    lastPromptReset = now;
  }
  if (promptCallCount >= 5) return Promise.resolve(null);
  promptCallCount++;
  
  // Sanitize message using DOMSanitizer
  const sanitizedMessage = DOMSanitizer.sanitizeText(message).substring(0, 500);
  
  return new Promise((resolve) => {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    
    const dialog = document.createElement('div');
    dialog.className = 'modal-dialog';
    
    const messageEl = document.createElement('p');
    messageEl.textContent = sanitizedMessage;
    
    const input = document.createElement('input');
    input.type = 'text';
    input.value = defaultValue;
    input.className = 'modal-input';
    
    const buttons = document.createElement('div');
    buttons.className = 'modal-buttons';
    
    const cancelBtn = document.createElement('button');
    cancelBtn.textContent = 'Cancel';
    cancelBtn.className = 'modal-button cancel';
    
    const okBtn = document.createElement('button');
    okBtn.textContent = 'OK';
    okBtn.className = 'modal-button ok';
    
    cancelBtn.onclick = () => { document.body.removeChild(modal); resolve(null); };
    okBtn.onclick = () => { 
      const sanitizedValue = DOMSanitizer.sanitizeText(input.value);
      document.body.removeChild(modal); 
      resolve(sanitizedValue); 
    };
    
    buttons.appendChild(cancelBtn);
    buttons.appendChild(okBtn);
    dialog.appendChild(messageEl);
    dialog.appendChild(input);
    dialog.appendChild(buttons);
    modal.appendChild(dialog);
    document.body.appendChild(modal);
    
    input.focus();
    input.select();
  });
}

// Secure confirm replacement
function secureConfirm(message) {
  // Rate limiting - max 5 confirms per 60 seconds
  const now = Date.now();
  if (now - lastPromptReset > 60000) {
    promptCallCount = 0;
    lastPromptReset = now;
  }
  if (promptCallCount >= 5) return Promise.resolve(false);
  promptCallCount++;
  
  // Sanitize message using DOMSanitizer
  const sanitizedMessage = DOMSanitizer.sanitizeText(message).substring(0, 500);
  
  return new Promise((resolve) => {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    
    const dialog = document.createElement('div');
    dialog.className = 'modal-dialog';
    
    const messageEl = document.createElement('p');
    messageEl.textContent = sanitizedMessage;
    messageEl.className = 'modal-message';
    
    const buttons = document.createElement('div');
    buttons.className = 'modal-buttons';
    
    const cancelBtn = document.createElement('button');
    cancelBtn.textContent = 'Cancel';
    cancelBtn.className = 'modal-button cancel';
    
    const okBtn = document.createElement('button');
    okBtn.textContent = 'OK';
    okBtn.className = 'modal-button ok';
    
    cancelBtn.onclick = () => { document.body.removeChild(modal); resolve(false); };
    okBtn.onclick = () => { document.body.removeChild(modal); resolve(true); };
    
    buttons.appendChild(cancelBtn);
    buttons.appendChild(okBtn);
    dialog.appendChild(messageEl);
    dialog.appendChild(buttons);
    modal.appendChild(dialog);
    document.body.appendChild(modal);
  });
}

// Dark mode toggle function
function toggleDarkMode() {
  const currentTheme = document.documentElement.getAttribute('data-theme');
  const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', newTheme);
  localStorage.setItem('theme', newTheme);
}

// Load saved theme
function loadTheme() {
  const savedTheme = localStorage.getItem('theme');
  const theme = savedTheme || 'dark'; // Default to dark for marketing site
  document.documentElement.setAttribute('data-theme', theme);
}

// Email validation
function validateEmail(email) {
  const sanitized = DOMSanitizer.sanitizeEmail(email);
  return sanitized !== '';
}

// Authentication helpers
function getUserEmail() {
  return localStorage.getItem('userEmail') || '';
}

async function handleLogout() {
  AuthUtils.logout();
}

// Toggle mobile menu
function toggleMenu() {
  const navMenu = document.getElementById('navMenu');
  if (navMenu) {
    navMenu.classList.toggle('active');
  }
}

// Load header dynamically
async function loadHeader() {
  try {
    const response = await fetch('./shared/header.html');
    if (response.ok) {
      const headerHTML = await response.text();
      const headerPlaceholder = document.getElementById('header-placeholder');
      if (headerPlaceholder) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(headerHTML, 'text/html');
        headerPlaceholder.textContent = '';
        while (doc.body.firstChild) {
          headerPlaceholder.appendChild(doc.body.firstChild);
        }
      }
    }
  } catch (error) {
    console.error('Failed to load header:', error);
  }
}

// Load footer dynamically
async function loadFooter() {
  try {
    const response = await fetch('./shared/footer.html');
    if (response.ok) {
      const footerHTML = await response.text();
      const footerPlaceholder = document.getElementById('footer-placeholder');
      if (footerPlaceholder) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(footerHTML, 'text/html');
        footerPlaceholder.textContent = '';
        while (doc.body.firstChild) {
          footerPlaceholder.appendChild(doc.body.firstChild);
        }
      }
    }
  } catch (error) {
    console.error('Failed to load footer:', error);
  }
}

// Smooth scrolling for anchor links
document.addEventListener('DOMContentLoaded', async function() {
    loadTheme();
    loadHeader();
    loadFooter();
    updateRegistrationLinks();
    
    // Optional authentication check for protected pages
    const isProtectedPage = document.body.classList.contains('protected-page');
    if (isProtectedPage) {
      const user = await AuthUtils.requireAuth();
      if (!user) return;
      
      // Store user info for compatibility
      localStorage.setItem('userEmail', user.email);
    }
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('a[href^="#"]');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Track page views
    trackPageView();
    setupAnalytics();
});

// Analytics and tracking
function trackPageView() {
    const page = window.location.pathname;
    const referrer = document.referrer;
    
    console.log('Page view:', {
        page: page,
        referrer: referrer,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent
    });
}

function setupAnalytics() {
    // Track button clicks
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('click', function() {
            const action = this.textContent.trim();
            const href = this.getAttribute('href');
            
            console.log('Button click:', {
                action: action,
                href: href,
                timestamp: new Date().toISOString()
            });
        });
    });

    // Track form submissions
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', function() {
            const formId = this.id || 'unknown';
            
            console.log('Form submission:', {
                formId: formId,
                timestamp: new Date().toISOString()
            });
        });
    });
}

// Pricing calculator
export function calculatePricing(plan, computers = 1, years = 1) {
    const prices = {
        standard: 99,
        premium: 199,
        professional: 299
    };
    
    let total = prices[plan] || 0;
    
    if (plan === 'premium') {
        total = total * Math.min(computers, 5);
    } else if (plan === 'professional') {
        // Professional plan uses base price as-is
    }
    
    total = total * years;
    
    return {
        monthly: total / (12 * years),
        yearly: total / years,
        total: total
    };
}

// API functions
export async function submitSignup(userData) {
    try {
        const response = await fetch(`${window.API_BASE_URL}/api/signup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(userData)
        });
        
        return await response.json();
    } catch (error) {
        console.error('Signup error:', error);
        return { success: false, message: 'Network error. Please try again.' };
    }
}

export async function submitContact(contactData) {
    try {
        const response = await fetch(`${window.API_BASE_URL}/api/contact`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(contactData)
        });
        
        return await response.json();
    } catch (error) {
        console.error('Contact error:', error);
        return { success: false, message: 'Network error. Please try again.' };
    }
}

// Utility functions
export function formatCurrency(amount, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency
    }).format(amount);
}

export function formatDate(date) {
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    }).format(new Date(date));
}

// Show download form for existing customers
function showDownloadForm() {
  const modal = document.createElement('div');
  modal.className = 'modal-overlay';
  modal.innerHTML = `
    <div class="modal-dialog" style="max-width: 400px;">
      <h3 style="margin-bottom: 1rem; color: var(--title-color);">Download Installer</h3>
      <p style="margin-bottom: 1rem; color: var(--text-color);">Enter your account name to download the AIPrivateSearch installer.</p>
      <input type="text" id="accountName" placeholder="Account Name" class="modal-input" style="margin-bottom: 1rem;">
      <div class="modal-buttons">
        <button class="modal-button cancel" onclick="closeDownloadForm()">Cancel</button>
        <button class="modal-button ok" onclick="handleDownload()">Download</button>
      </div>
    </div>
  `;
  modal.id = 'downloadModal';
  document.body.appendChild(modal);
  document.getElementById('accountName').focus();
}

function closeDownloadForm() {
  const modal = document.getElementById('downloadModal');
  if (modal) {
    document.body.removeChild(modal);
  }
}

function handleDownload() {
  const accountName = document.getElementById('accountName').value.trim();
  if (!accountName) {
    showUserMessage('Please enter your account name');
    return;
  }
  
  // Sanitize account name
  const sanitizedAccount = DOMSanitizer.sanitizeText(accountName);
  
  // Close modal
  closeDownloadForm();
  
  // Trigger download
  const downloadUrl = '/downloads/AIPrivateSearch-Installer.dmg';
  const link = document.createElement('a');
  link.href = downloadUrl;
  link.download = 'AIPrivateSearch-Installer.dmg';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  
  showUserMessage(`Download started for account: ${sanitizedAccount}`);
}

// Environment detection and URL configuration
function getCustomerRegistrationUrl() {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:56303/customer-registration.html';
  } else {
    return 'https://custmgr.aiprivatesearch.com/customer-registration.html';
  }
}

function getDeviceRegistrationUrl() {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:56303/device-registration.html';
  } else {
    return 'https://custmgr.aiprivatesearch.com/device-registration.html';
  }
}

// Update registration links on page load
function updateRegistrationLinks() {
  const customerRegUrl = getCustomerRegistrationUrl();
  const deviceRegUrl = getDeviceRegistrationUrl();
  
  const customerLinks = document.querySelectorAll('a[href="http://localhost:56303/customer-registration.html"]');
  customerLinks.forEach(link => {
    link.href = customerRegUrl;
  });
  
  const deviceLinks = document.querySelectorAll('a[href="http://localhost:56303/device-registration.html"]');
  deviceLinks.forEach(link => {
    link.href = deviceRegUrl;
  });
}

// Make functions globally available
if (typeof window !== 'undefined') {
  window.showUserMessage = showUserMessage;
  window.securePrompt = securePrompt;
  window.secureConfirm = secureConfirm;
  window.toggleDarkMode = toggleDarkMode;
  window.toggleMenu = toggleMenu;
  window.validateEmail = validateEmail;
  window.getUserEmail = getUserEmail;
  window.handleLogout = handleLogout;
  window.showDownloadForm = showDownloadForm;
  window.closeDownloadForm = closeDownloadForm;
  window.handleDownload = handleDownload;
  window.getCustomerRegistrationUrl = getCustomerRegistrationUrl;
  window.getDeviceRegistrationUrl = getDeviceRegistrationUrl;
}

window.AIPrivateSearchWeb = {
    calculatePricing,
    submitSignup,
    submitContact,
    formatCurrency,
    formatDate
};