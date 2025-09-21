"""
Security Utilities for LegalLens
===============================

Utilities for encoding/decoding sensitive configuration data.
"""

import base64
import json
import os
from typing import Dict, Any, Optional

def decode_base64_to_json(base64_string: str) -> Dict[Any, Any]:
    """
    Decode a base64 string back to JSON.
    
    Args:
        base64_string: Base64 encoded string
        
    Returns:
        Decoded JSON as dictionary
    """
    try:
        # Decode from base64
        decoded_bytes = base64.b64decode(base64_string.encode('utf-8'))
        json_content = decoded_bytes.decode('utf-8')
        
        # Parse JSON
        return json.loads(json_content)
    
    except Exception as e:
        raise Exception(f"Error decoding base64 to JSON: {str(e)}")

def get_service_account_credentials() -> Optional[Dict[Any, Any]]:
    """
    Get service account credentials from environment variables.
    Prioritizes base64 encoded credentials over file path.
    
    Returns:
        Service account credentials as dictionary or None
    """
    try:
        # Try to get from base64 environment variable first (for Docker/production)
        base64_key = os.getenv('FIREBASE_SERVICE_ACCOUNT_KEY_B64')
        if base64_key:
            return decode_base64_to_json(base64_key)
        
        # Fall back to environment variable with file path (for development)
        file_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_KEY') or os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if file_path and os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as file:
                return json.load(file)
        
        return None
    
    except Exception as e:
        raise Exception(f"Error getting service account credentials: {str(e)}")

def is_running_in_docker() -> bool:
    """
    Check if the application is running inside a Docker container.
    
    Returns:
        True if running in Docker, False otherwise
    """
    return os.path.exists('/.dockerenv') or os.getenv('FIREBASE_SERVICE_ACCOUNT_KEY_B64') is not None