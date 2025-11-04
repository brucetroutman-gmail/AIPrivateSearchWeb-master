# AIPrivateSearch Marketing Website - Technical Specifications v1.01

## Overview
Professional marketing website for AIPrivateSearch platform with secure authentication, lead generation, and pricing calculator functionality.

## Architecture

### Frontend Structure
```
/client/c01_client-marketing/
├── assets/images/          # Marketing assets
├── config/app.json         # App configuration
├── shared/
│   ├── utils/
│   │   ├── authUtils.js    # Authentication utilities
│   │   └── domSanitizer.js # XSS prevention
│   ├── common.js           # Core functionality
│   └── styles.css          # Global styles
├── csrf.js                 # CSRF protection
├── index.html              # Landing page
└── login.html              # Authentication page
```

### Backend Structure
```
/server/s01_server-marketing/
├── routes/
│   └── auth.mjs           # Authentication endpoints
└── server.mjs             # Express server
```

## Security Implementation

### ESLint Security Rules
- **Code Injection Prevention**: `no-eval`, `security/detect-eval-with-expression`
- **XSS Protection**: `no-unsanitized/method`, `no-unsanitized/property`
- **Path Traversal**: `security/detect-non-literal-fs-filename`
- **Buffer Security**: `security/detect-buffer-noassert`
- **CSRF Protection**: Token-based validation

### Authentication System
- **Bearer Token**: UUID-based session management
- **Session Expiry**: 24-hour automatic cleanup
- **Rate Limiting**: Client-side request throttling
- **Input Sanitization**: DOMSanitizer for all user inputs

## API Endpoints

### Authentication Routes (`/api/auth`)
- `POST /register` - User registration
- `POST /login` - User authentication
- `GET /me` - Current user info
- `POST /logout` - Session termination

### Marketing Routes (`/api`)
- `GET /csrf-token` - CSRF token generation
- `POST /signup` - Lead capture
- `POST /contact` - Contact form submission

## Missing Components (To Be Implemented)

### Required Pages
- `pricing.html` - Pricing tiers and calculator
- `signup.html` - Registration form
- `download.html` - Software download page
- `contact.html` - Contact form
- `privacy.html` - Privacy policy
- `terms.html` - Terms of service

### Form Implementations
- Registration form with validation
- Contact form with CSRF protection
- Pricing calculator with plan selection
- Error handling and user feedback

## Dependencies

### Production
- `express@^4.18.2` - Web server
- `cors@^2.8.5` - Cross-origin requests
- `dotenv@^16.4.5` - Environment variables
- `uuid` - Session ID generation (missing)

### Development
- `eslint@^9.39.1` - Code linting
- `eslint-plugin-security@^3.0.1` - Security rules
- `eslint-plugin-no-unsanitized@^4.1.4` - XSS prevention

## Configuration

### Environment Variables
```bash
PORT=3002
NODE_ENV=development
```

### App Configuration (`config/app.json`)
```json
{
  "app-name": "AIPrivateSearch Marketing",
  "bearer-token-timeout": 300,
  "subscription-tier": 1
}
```

## Security Status
- ✅ ESLint security checks passing
- ✅ CSRF protection implemented
- ✅ Input sanitization active
- ✅ Session management secure
- ⚠️ Missing UUID dependency
- ⚠️ Plain text passwords (dev only)

## Development Scripts
- `npm start` - Production server
- `npm run dev` - Development with watch
- `npm run lint` - Code quality check
- `npm run lint:security` - Security audit
- `npm run security-check` - Full security scan

## Completion Status
- **Security**: 95% (excellent foundation)
- **Backend**: 80% (core functionality ready)
- **Frontend**: 40% (missing key pages)
- **Forms**: 20% (basic structure only)
- **Overall**: 60% complete

## Next Phase Requirements
1. Install `uuid` dependency
2. Create missing HTML pages
3. Implement form validation
4. Add error handling
5. Create legal pages
6. Add loading states
7. Implement pricing calculator