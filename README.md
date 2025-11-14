# AIPrivateSearch Marketing Website

## Executive Summary

AIPrivateSearch Marketing Website is a professional Node.js ES6 application that showcases the AIPrivateSearch platform. Built with modern web technologies, it provides comprehensive information about features, pricing, and enables user registration and contact management.

**Key Features:**
- **Professional Design**: Modern, responsive interface with light/dark themes
- **Secure Authentication**: Bearer token-based user authentication system
- **Lead Generation**: Contact forms and signup flows for customer acquisition
- **Pricing Calculator**: Interactive pricing for Standard, Premium, and Professional tiers
- **Security**: CSRF protection, input sanitization, and secure session management

**Use Cases:**
- Product marketing and lead generation
- Customer onboarding and registration
- Pricing information and plan comparison
- Professional business presentation

## How to Get Started

### Prerequisites
- **Node.js** (v16+ recommended)
- **Internet connection** (for dependencies)

### Quick Start (1 Minute)

#### 1. Install Dependencies
```bash
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb
npm install
```

#### 2. Start Marketing Website
```bash
npm start
```

#### 3. Access Website
- **Marketing Site**: http://localhost:56302

### Development Workflow

### Amazon Q Release Command
For developers using Amazon Q Developer, use the **"release"** command to streamline version management:

**Minor Version Bump:**
```
release
```

**Major Version Bump:**
```
release 2
```

This command:
1. **Minor bump** (`release`): Increments version by 0.01 (e.g., 1.03 → 1.04)
2. **Major bump** (`release N`): Sets version to N.00 (e.g., `release 2` → 2.00)
3. Updates version in README.md and package.json
4. Generates commit message in format: `vX.XX: [description of changes]`
5. **Note**: Does not automatically commit - you must manually commit the changes

**Setup in new chat sessions:**
```
I have a 'release' command that bumps version by 0.01, or 'release N' for major version N.00
```

## Architecture

### Client Structure
- **`/client/c01_client-marketing/`**: Frontend application
  - **`shared/`**: Common utilities (auth, sanitization, CSRF)
  - **`config/`**: Application configuration
  - **HTML pages**: Landing, pricing, signup, login

### Server Structure  
- **`/server/s01_server-marketing/`**: Backend API server
  - **`routes/`**: Authentication and API endpoints
  - **Express.js**: ES6 module-based server

### Security Features
- **Authentication**: Bearer token-based sessions
- **CSRF Protection**: Token-based request validation
- **Input Sanitization**: XSS prevention and data validation
- **Rate Limiting**: Protection against abuse
- **Secure Sessions**: Automatic expiry and cleanup

### Technology Stack
- **Frontend**: Vanilla JavaScript ES6, CSS3, HTML5
- **Backend**: Node.js, Express.js ES6 modules
- **Security**: CSRF tokens, input sanitization, session management
- **Styling**: CSS variables, responsive design, theme system

---

**Version**: 1.08 | **License**: [Creative Commons Attribution-NonCommercial (CC BY-NC-ND)](https://creativecommons.org/licenses/by-nc-nd/4.0/) | **Website**: AIPrivateSearch Marketing