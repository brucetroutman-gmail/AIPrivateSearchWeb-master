// API Configuration - reads backend port from app.json
(function() {
  let API_BASE_URL = 'http://localhost:3002';
  
  // Load API configuration from app.json synchronously
  try {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', './config/app.json', false); // synchronous
    xhr.send();
    if (xhr.status === 200) {
      const config = JSON.parse(xhr.responseText);
      console.log('Marketing - Loaded config:', config);
      if (config.ports && config.ports.backend) {
        API_BASE_URL = `http://localhost:${config.ports.backend}`;
        console.log('Marketing - Set API_BASE_URL to:', API_BASE_URL);
      }
    }
  } catch (error) {
    console.warn('Marketing - Could not load API config, using default port 3002:', error);
  }
  
  // Set global API base URL
  window.API_BASE_URL = API_BASE_URL;
  console.log('Marketing - Final API_BASE_URL:', window.API_BASE_URL);
})();