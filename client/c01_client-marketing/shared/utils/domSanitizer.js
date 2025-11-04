// DOM sanitization utility for marketing website
class DOMSanitizer {
  // Sanitize text input by removing HTML tags and dangerous characters
  static sanitizeText(input) {
    if (typeof input !== 'string') return '';
    return input
      .replace(/[<>\"'&]/g, (match) => {
        const entities = { '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#x27;', '&': '&amp;' };
        return entities[match];
      });
  }

  // Sanitize URL input
  static sanitizeURL(url) {
    if (typeof url !== 'string') return '';
    try {
      const parsed = new URL(url);
      return ['http:', 'https:'].includes(parsed.protocol) ? parsed.href : '';
    } catch {
      return '';
    }
  }

  // Clear element content safely
  static clearElement(element) {
    element.textContent = '';
  }

  // Set text content safely with sanitization
  static setTextContent(element, text) {
    element.textContent = this.sanitizeText(text);
  }

  // Create element with sanitized text content
  static createElement(tagName, textContent = '', className = '') {
    const element = document.createElement(tagName);
    if (textContent) element.textContent = this.sanitizeText(textContent);
    if (className) element.className = this.sanitizeText(className);
    return element;
  }

  // Validate and sanitize email
  static sanitizeEmail(email) {
    if (typeof email !== 'string') return '';
    const sanitized = this.sanitizeText(email);
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(sanitized) ? sanitized : '';
  }
}

// Make globally available
window.DOMSanitizer = DOMSanitizer;

// ES6 export
export { DOMSanitizer };