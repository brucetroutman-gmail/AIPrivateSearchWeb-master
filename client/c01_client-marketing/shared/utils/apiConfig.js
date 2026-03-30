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
      if (config.ports && config.ports.backend) {
        API_BASE_URL = `http://localhost:${config.ports.backend}`;
      }
    }
  } catch (_error) { // eslint-disable-line no-unused-vars
    // Use default API_BASE_URL if config load fails
  }
  
  // Set global API_BASE_URL
  window.API_BASE_URL = API_BASE_URL;
})();