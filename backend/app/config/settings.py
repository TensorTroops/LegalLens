"""
Simple Configuration for Document AI
====================================
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Simple settings for Document AI service."""
    
    # Application
    APP_NAME: str = "LegalLens Document AI"
    DEBUG: bool = False
    
    # API Configuration
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8080
    
    # Google Cloud
    GCP_PROJECT_ID: str
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None
    
    # Document AI
    DOCUMENT_AI_PROCESSOR_ID: str
    DOCUMENT_AI_LOCATION: str = "us"
    
    # Firebase - support both file path and base64 encoded key
    FIREBASE_PROJECT_ID: Optional[str] = None
    FIREBASE_SERVICE_ACCOUNT_KEY: Optional[str] = None
    FIREBASE_SERVICE_ACCOUNT_KEY_B64: Optional[str] = None
    
    # Spanner Configuration
    SPANNER_INSTANCE_ID: str
    SPANNER_DATABASE_ID: str
    
    # Gemini AI Configuration
    GEMINI_API_KEY: Optional[str] = None
    
    # Storage
    GCS_BUCKET_NAME: str
    
    @property
    def is_production(self) -> bool:
        """Check if running in production (Google Cloud App Engine)."""
        return os.getenv('GAE_ENV', '').startswith('standard')
    
    @property
    def firebase_credentials_available(self) -> bool:
        """Check if Firebase credentials are available (either file or base64)."""
        return bool(self.FIREBASE_SERVICE_ACCOUNT_KEY_B64 or self.FIREBASE_SERVICE_ACCOUNT_KEY)
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

def get_settings() -> Settings:
    """Get settings instance."""
    return Settings()