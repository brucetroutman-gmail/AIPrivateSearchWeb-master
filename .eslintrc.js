module.exports = {
  extends: ['./security/eslint.config.mjs'],
  rules: {
    // Allow console statements in development
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn'
  }
};