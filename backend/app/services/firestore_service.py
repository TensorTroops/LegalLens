"""
Firestore Service for User Data Management
==========================================
"""

import logging
from datetime import datetime
from typing import Dict, List, Optional
from google.cloud import firestore
from firebase_admin import credentials, firestore as admin_firestore, initialize_app
from app.config.settings import get_settings
from app.utils.security import get_service_account_credentials

logger = logging.getLogger(__name__)

class FirestoreService:
    """Service for interacting with Firestore database."""
    
    def __init__(self):
        self.settings = get_settings()
        self._initialize_firebase()
        
        # Only initialize Firestore client if Firebase was successfully initialized
        try:
            self.db = admin_firestore.client()
        except Exception as e:
            logger.warning(f"Could not initialize Firestore client: {str(e)}")
            self.db = None
    
    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK with secure credential handling."""
        try:
            # Check if Firebase app is already initialized
            from firebase_admin import _apps
            if not _apps:
                # Get credentials using the security utility
                credentials_dict = get_service_account_credentials()
                
                if credentials_dict:
                    # Use the decoded credentials dictionary
                    cred = credentials.Certificate(credentials_dict)
                    logger.info("Using base64/file-based service account credentials")
                else:
                    # For local development without credentials, skip Firebase initialization
                    logger.warning("No Firebase credentials found. Firebase services will be unavailable.")
                    return
                
                initialize_app(cred, {
                    'projectId': self.settings.FIREBASE_PROJECT_ID or self.settings.GCP_PROJECT_ID
                })
                
                logger.info("Firebase Admin SDK initialized successfully")
                
        except Exception as e:
            logger.error(f"Error initializing Firebase: {str(e)}")
            logger.warning("Firebase services will be unavailable")
            # Don't raise the exception, let the app continue without Firebase
    
    async def save_user_summary(self, user_email: str, summary_data: Dict) -> Optional[str]:
        """
        Save user summary to Firestore with structure: users/{email}/summaries/{doc_id}
        Using email as the document ID for simpler access
        
        Args:
            user_email: User's email address
            summary_data: Dictionary containing summary information
            
        Returns:
            Document ID if successful, None otherwise
        """
        try:
            # Use email directly as the document ID (replace dots with underscores for Firebase compatibility)
            safe_email = user_email
            
            # Prepare the summary document
            doc_data = {
                'original_text': summary_data.get('original_text', ''),
                'simplified_text': summary_data.get('simplified_text', ''),
                'extracted_terms': summary_data.get('extracted_terms', []),
                'document_title': summary_data.get('document_title', 'Untitled Document'),
                'created_at': datetime.utcnow(),
                'updated_at': datetime.utcnow(),
                'user_email': user_email,
                'processing_status': summary_data.get('processing_status', 'completed'),
                'terms_count': summary_data.get('terms_count', 0),
                'spanner_matches': summary_data.get('spanner_matches', 0),
                'gemini_fallbacks': summary_data.get('gemini_fallbacks', 0)
            }
            
            # Save to Firestore: users/{safe_email}/summaries/{auto_generated_id}
            user_doc_ref = self.db.collection('users').document(safe_email)
            summary_ref = user_doc_ref.collection('summaries').document()
            
            summary_ref.set(doc_data)
            
            logger.info(f"Summary saved for user {user_email} with summary ID: {summary_ref.id}")
            return summary_ref.id
            
        except Exception as e:
            logger.error(f"Error saving summary for user {user_email}: {str(e)}")
            return None
    
    async def get_user_summaries(self, user_email: str, limit: int = 10) -> List[Dict]:
        """
        Get user's saved summaries using the new email-based structure.
        
        Args:
            user_email: User's email address
            limit: Maximum number of summaries to return
            
        Returns:
            List of summary documents
        """
        try:
            # Use safe email format for document ID
            safe_email = user_email.replace('.', '_').replace('@', '_at_')
            
            # Get summaries from user's subcollection
            user_doc_ref = self.db.collection('users').document(safe_email)
            summaries_ref = user_doc_ref.collection('summaries')
            
            # Query summaries ordered by creation date (newest first)
            query = summaries_ref.order_by('created_at', direction=firestore.Query.DESCENDING).limit(limit)
            docs = query.stream()
            
            summaries = []
            for doc in docs:
                summary_data = doc.to_dict()
                summary_data['id'] = doc.id
                summaries.append(summary_data)
            
            return summaries
            
        except Exception as e:
            logger.error(f"Error getting summaries for user {user_email}: {str(e)}")
            return []
    
    async def get_summary_by_id(self, user_email: str, summary_id: str) -> Optional[Dict]:
        """
        Get a specific summary by ID using the new email-based structure.
        
        Args:
            user_email: User's email address
            summary_id: Summary document ID
            
        Returns:
            Summary document if found, None otherwise
        """
        try:
            # Use safe email format for document ID
            safe_email = user_email.replace('.', '_').replace('@', '_at_')
            
            # Get specific summary
            user_doc_ref = self.db.collection('users').document(safe_email)
            summary_ref = user_doc_ref.collection('summaries').document(summary_id)
            
            doc = summary_ref.get()
            if doc.exists:
                summary_data = doc.to_dict()
                summary_data['id'] = doc.id
                return summary_data
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting summary {summary_id} for user {user_email}: {str(e)}")
            return None
    
    async def delete_summary(self, user_email: str, summary_id: str) -> bool:
        """
        Delete a user's summary using the new email-based structure.
        
        Args:
            user_email: User's email address
            summary_id: Summary document ID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Use safe email format for document ID
            safe_email = user_email.replace('.', '_').replace('@', '_at_')
            
            # Delete the summary
            user_doc_ref = self.db.collection('users').document(safe_email)
            summary_ref = user_doc_ref.collection('summaries').document(summary_id)
            
            summary_ref.delete()
            logger.info(f"Summary {summary_id} deleted for user {user_email}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting summary {summary_id} for user {user_email}: {str(e)}")
            return False
    
    async def update_user_profile(self, user_email: str, profile_data: Dict) -> bool:
        """
        Update user profile information.
        
        Args:
            user_email: User's email address
            profile_data: Dictionary containing profile information
            
        Returns:
            True if successful, False otherwise
        """
        try:
            user_doc_ref = self.db.collection('users').document(user_email)
            
            # Add updated timestamp
            profile_data['updated_at'] = datetime.utcnow()
            
            user_doc_ref.set(profile_data, merge=True)
            logger.info(f"Profile updated for user {user_email}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating profile for user {user_email}: {str(e)}")
            return False