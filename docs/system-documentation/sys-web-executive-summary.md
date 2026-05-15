# sys-web-executive-summary.md

## What It Is

AIPrivateSearch Marketing Website is the public-facing marketing and distribution site for the AIPrivateSearch platform. It is a Node.js ES6 application that serves product information, handles lead generation, and distributes the macOS installer DMG.

## Problem It Solves

Provides a professional web presence for AIPrivateSearch that:
- Explains the product to prospective customers
- Captures leads via contact and signup forms
- Distributes the signed and notarized macOS DMG installer
- Links customers to the custmgr registration system

## Key Features

| Feature | Description |
|---------|-------------|
| Marketing pages | Landing, pricing, group, videos, download |
| Lead generation | Contact form, Get Started signup flow |
| DMG distribution | Serves signed/notarized AIPrivateSearch.dmg |
| Authentication | Bearer token login for protected pages |
| CSRF protection | Token-based request validation |
| Installer pipeline | build-all.sh builds, signs, notarizes, and deploys DMG |

## How It Fits in the Suite

```
aiprivatesearchweb  ←  public marketing site, DMG distribution
       ↓
aiprivatesearchcustmgr  ←  customer registration, licensing, device management
       ↓
aiprivatesearch  ←  installed Mac app, AI search engine
```

- Web site links to custmgr for customer registration
- Web site distributes the DMG that installs aiprivatesearch
- Custmgr validates device licenses used by aiprivatesearch

## Current Version and Status

- **Version**: 1.59
- **Status**: Production
- **URL**: https://aiprivatesearch.com
- **Server**: Ubuntu Linux (formr/aiprivatesearch.com)
- **Frontend port**: 56302
- **Backend port**: 56303
