# sys-web-todo.md

## Pending

### Installer & Distribution
- [ ] Add `.env-aips` file bundling in DMG for new installs
- [ ] Revisit Ollama installation location — consider `/Applications` or `/usr/local/bin` instead of `/Users/Shared/AIPrivateSearch`
- [ ] Add Intel Mac (x86_64) DMG option or detect architecture on download page

### Backend & API
- [ ] Persist signup and contact form submissions to database (currently console.log only)
- [ ] Implement server-side CSRF token validation (currently stateless)
- [ ] Add rate limiting to API endpoints
- [ ] Connect Get Started flow to custmgr registration API
- [ ] Connect pricing page to custmgr for live plan data

### Marketing & SEO
- [ ] Implement Google Analytics and conversion tracking
- [ ] Add SEO optimization and meta tags
- [ ] Add customer testimonials and case studies section
- [ ] Create blog/news section for content marketing
- [ ] Add video testimonials and product demos
- [ ] Create competitive comparison pages

### Security & Compliance
- [ ] Add GDPR compliance and cookie consent
- [ ] Add audit logging for user actions

### Technical
- [ ] Implement progressive web app (PWA) features
- [ ] Optimize page load speeds and performance
- [ ] Add multi-language support (i18n)
- [ ] Implement automated testing suite

## Known Issues

- `spctl --assess` shows "Insufficient Context" locally — expected, works correctly on downloaded DMG
- Signup/contact endpoints log to console only — no email or database integration yet

## Completed

- [x] Apple code signing and notarization via build-all.sh
- [x] Swift universal binary launcher (arm64 + x86_64)
- [x] Git LFS for DMG distribution
- [x] Progress dialogs with auto-dismiss (giving up after 3)
- [x] Silent background start for No option
- [x] ESLint 0 errors, 0 warnings
- [x] Remove System Events / Terminal AppleScript permission prompts
- [x] Default No button on details dialogs
- [x] Privacy policy and terms of service pages
- [x] Responsive design with light/dark themes
- [x] CSRF protection and input sanitization
- [x] Bearer token authentication
- [x] PM2 deployment with ecosystem.config.cjs
- [x] Separate frontend/backend architecture (ports 56302/56303)
- [x] Dark mode as default theme
