# sys-web-api.md

## Base URL

```
http://localhost:56303
```

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/csrf-token` | None | Returns a CSRF token |
| POST | `/api/signup` | None | Lead capture / account creation |
| POST | `/api/contact` | None | Contact form submission |
| POST | `/api/auth/login` | None | Admin login |
| POST | `/api/auth/logout` | Bearer | Admin logout |
| GET | `/api/auth/status` | Bearer | Check session status |

## Endpoint Details

### GET /api/csrf-token
Returns a random CSRF token for form submissions.

**Response:**
```json
{ "csrfToken": "abc123xyz456" }
```

### POST /api/signup
Captures lead/signup data.

**Request:**
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane@example.com",
  "company": "Acme",
  "industry": "Technology",
  "plan": "standard"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account created successfully!",
  "downloadUrl": "/download?registered=true"
}
```

### POST /api/contact
Submits a contact form message.

**Request:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "subject": "Question",
  "message": "Hello..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Thank you for your message. We'll get back to you soon!"
}
```

### POST /api/auth/login
Admin login with email and password.

**Request:**
```json
{ "email": "admin@example.com", "password": "password" }
```

**Response:**
```json
{ "success": true, "token": "bearer-token", "user": { "email": "..." } }
```

## Auth

Protected routes require `Authorization: Bearer <token>` header. Tokens are issued on login and expire automatically.

## Notes

- No rate limiting currently implemented
- Signup and contact endpoints log to console only — no database persistence yet
- CSRF tokens are stateless (random, not validated server-side yet)
