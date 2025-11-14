// API Configuration for Marketing Website
(function() {
  'use strict';
  
  // Read app.json synchronously to get backend port
  let API_BASE_URL = 'http://localhost:3002'; // Default fallback
  
  try {
    // Use XMLHttpRequest for synchronous loading
    const xhr = new XMLHttpRequest();
    xhr.open('GET', './config/app.json', false); // false = synchronous
    xhr.send();
    
    if (xhr.status === 200) {
      const config = JSON.parse(xhr.responseText);
      console.log('Loaded config:', config);
      
      if (config.ports && config.ports.backend) {
        API_BASE_URL = `http://localhost:${config.ports.backend}`;
        console.log('Set API_BASE_URL to:', API_BASE_URL);
      }
    }
  } catch (error) {
    console.warn('Failed to load app.json, using default API_BASE_URL:', error);
  }
  
  // Set global API_BASE_URL
  window.API_BASE_URL = API_BASE_URL;
  console.log('Final API_BASE_URL:', window.API_BASE_URL);
})();