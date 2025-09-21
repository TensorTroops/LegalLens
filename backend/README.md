# 🐳 LegalLens Backend - Docker Deployment

## Quick Start

This backend is now configured for Docker-based deployment with encrypted JSON credentials.

### 📁 Key Files

- `Dockerfile` - Container configuration
- `encrypt_json.py` - JSON to base64 encryption script  
- `.dockerignore` - Files excluded from container
- `DOCKER_DEPLOYMENT.md` - Complete deployment guide
- `quick_deploy.py` - Interactive deployment helper

### 🚀 Quick Deployment

1. **Encrypt credentials:**
   ```bash
   python encrypt_json.py
   ```

2. **Build image:**
   ```bash
   docker build -t legallens-backend .
   ```

3. **Deploy to Google Cloud Run:**
   ```bash
   gcloud builds submit --tag gcr.io/legallens-b5f95/legallens-backend:latest .
   gcloud run deploy legallens-backend --image gcr.io/legallens-b5f95/legallens-backend:latest --env-vars-file .env.docker
   ```

### 🔐 Security Features

✅ **JSON credentials encrypted as base64**  
✅ **Sensitive files excluded from Docker image**  
✅ **Non-root container user**  
✅ **Environment-based configuration**  

### 📱 Frontend Integration

Update `frontend/lib/config/app_config.dart` with your Cloud Run URL:
```dart
static const String _prodApiHost = 'your-service-url.a.run.app';
```

### 📖 Documentation

- **Full Guide**: `DOCKER_DEPLOYMENT.md`
- **Interactive Setup**: `python quick_deploy.py`

---

**🎯 Ready for production deployment with Google Cloud Run!**