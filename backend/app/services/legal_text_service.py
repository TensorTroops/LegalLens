"""
Legal Text Simplification Service
=================================
"""

import logging
import re
from typing import Dict, List, Optional
from app.services.spanner_service import SpannerService
from app.services.gemini_service import GeminiService
from app.services.firestore_service import FirestoreService
from app.services.mock_data_service import MockDataService

logger = logging.getLogger(__name__)

class LegalTextSimplificationService:
    """Main service for processing and simplifying legal text."""
    
    def __init__(self):
        self.spanner_service = SpannerService()
        self.gemini_service = GeminiService()
        self.firestore_service = FirestoreService()
        self.mock_service = MockDataService()
    
    async def process_legal_document(self, extracted_text: str, user_email: str) -> Dict:
        """
        Enhanced workflow for comprehensive legal document processing.
        
        For test account (new@gmail.com), returns mock data immediately.
        For other accounts, processes normally with Gemini AI for comprehensive simplification.
        
        Args:
            extracted_text: Text extracted from the legal document
            user_email: Email of the user processing the document
            
        Returns:
            Dictionary containing simplified text and complex terms with definitions
        """
        try:
            logger.info(f"Processing legal document for user: {user_email}")
            
            # Check if this is the test account
            if MockDataService.is_test_account(user_email):
                logger.info("Test account detected - returning mock data")
                mock_summary = MockDataService.get_mock_summary()
                
                # Format the simplified text to remove unwanted characters
                formatted_simplified_text = MockDataService.format_response(mock_summary['simplified_text'])
                
                # Format mock data to match expected response structure
                return {
                    'original_text': mock_summary['original_text'],
                    'simplified_text': formatted_simplified_text,
                    'extracted_terms': mock_summary['extracted_terms'],
                    'processing_status': mock_summary['processing_status'],
                    'terms_count': mock_summary['terms_count'],
                    'spanner_matches': mock_summary['spanner_matches'],
                    'gemini_fallbacks': mock_summary['gemini_fallbacks'],
                    'processing_method': 'mock_data_test_account'
                }
            
            # New comprehensive processing using Gemini AI
            logger.info("Using Gemini AI for comprehensive text simplification and term extraction...")
            
            # Use the new comprehensive simplification method
            gemini_result = await self.gemini_service.comprehensive_simplification(extracted_text)
            
            # Format the response according to user requirements: {simplified text}\n[{term:meaning}]
            simplified_text = gemini_result['simplified_text']
            complex_terms = gemini_result['complex_terms']
            
            # Create the formatted response with simplified text and complex terms list
            if complex_terms:
                terms_list = []
                for term, meaning in complex_terms.items():
                    terms_list.append(f"{term}: {meaning}")
                
                formatted_response = f"{simplified_text}COMPLEX TERMS--------------\n[{chr(10).join(terms_list)}]"
            else:
                formatted_response = simplified_text
            
            # Format the response to remove unwanted characters
            formatted_response = MockDataService.format_response(formatted_response)
            
            # Convert complex terms to the expected format for compatibility
            extracted_terms = []
            for term, definition in complex_terms.items():
                extracted_terms.append({
                    'term': term,
                    'definition': definition,
                    'source': 'gemini_comprehensive',
                    'confidence': 'high'
                })
            
            # Prepare comprehensive result
            result = {
                'original_text': extracted_text,
                'simplified_text': formatted_response,
                'extracted_terms': extracted_terms,
                'processing_status': 'success',
                'terms_count': len(complex_terms),
                'spanner_matches': 0,  # Not using Spanner in new approach
                'gemini_matches': len(complex_terms),
                'original_word_count': gemini_result['original_word_count'],
                'simplified_word_count': gemini_result['simplified_word_count'],
                'reduction_percentage': gemini_result['reduction_percentage'],
                'processing_method': 'gemini_comprehensive_simplification'
            }
            
            logger.info(f"Successfully processed document with Gemini: {len(complex_terms)} terms extracted, "
                       f"word count reduced from {gemini_result['original_word_count']} to {gemini_result['simplified_word_count']} "
                       f"({gemini_result['reduction_percentage']}% reduction)")
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing legal document: {str(e)}")
            return {
                'original_text': extracted_text,
                'simplified_text': extracted_text,
                'extracted_terms': [],
                'processing_status': 'error',
                'error_message': str(e)
            }
    
    async def _replace_terms_with_definitions(self, text: str, definitions: Dict[str, str]) -> str:
        """
        Replace complex legal terms with their definitions in the text.
        
        Args:
            text: Original text
            definitions: Dictionary mapping terms to definitions
            
        Returns:
            Text with terms replaced by definitions
        """
        try:
            simplified_text = text
            
            # Sort terms by length (longest first) to avoid partial replacements
            sorted_terms = sorted(definitions.keys(), key=len, reverse=True)
            
            for term in sorted_terms:
                definition = definitions[term]
                
                # Create regex pattern for case-insensitive whole word matching
                pattern = re.compile(rf'\b{re.escape(term)}\b', re.IGNORECASE)
                
                # Replace with definition in parentheses
                replacement = f"{term} ({definition})"
                simplified_text = pattern.sub(replacement, simplified_text)
            
            return simplified_text
            
        except Exception as e:
            logger.error(f"Error replacing terms with definitions: {str(e)}")
            return text
    
    async def save_summary(self, user_email: str, summary_data: Dict, document_title: str = None) -> Optional[str]:
        """
        Save the processed summary to Firestore.
        For test account, returns mock document ID.
        
        Args:
            user_email: User's email address
            summary_data: Processed document data
            document_title: Optional title for the document
            
        Returns:
            Document ID if successful, None otherwise
        """
        try:
            # For test account, return mock document ID
            if MockDataService.is_test_account(user_email):
                logger.info(f"Test account detected - returning mock save for user: {user_email}")
                import random
                return f"mock_doc_{random.randint(100000, 999999)}"
            
            # Normal processing for non-test accounts
            firestore_data = {
                'original_text': summary_data.get('original_text', ''),
                'simplified_text': summary_data.get('simplified_text', ''),
                'extracted_terms': summary_data.get('extracted_terms', []),
                'document_title': document_title or 'Legal Document Summary',
                'processing_status': summary_data.get('processing_status', 'unknown'),
                'total_terms_found': summary_data.get('total_terms_found', 0),
                'spanner_terms': summary_data.get('spanner_terms', 0),
                'gemini_terms': summary_data.get('gemini_terms', 0),
                'processing_method': summary_data.get('processing_method', 'unknown')
            }
            
            doc_id = await self.firestore_service.save_user_summary(user_email, firestore_data)
            
            if doc_id:
                logger.info(f"Summary saved successfully for user {user_email} with ID: {doc_id}")
            
            return doc_id
            
        except Exception as e:
            logger.error(f"Error saving summary for user {user_email}: {str(e)}")
            return None
    
    async def get_user_summaries(self, user_email: str, limit: int = 10) -> List[Dict]:
        """
        Get user's saved summaries from Firestore.
        For test account, returns mock summaries.
        
        Args:
            user_email: User's email address
            limit: Maximum number of summaries to return
            
        Returns:
            List of summary documents
        """
        try:
            # For test account, return mock summaries
            if MockDataService.is_test_account(user_email):
                logger.info(f"Test account detected - returning mock summaries for user: {user_email}")
                return MockDataService.get_all_mock_summaries()[:limit]
            
            # Normal processing for non-test accounts
            return await self.firestore_service.get_user_summaries(user_email, limit)
        except Exception as e:
            logger.error(f"Error getting summaries for user {user_email}: {str(e)}")
            return []
    
    async def get_summary_by_id(self, user_email: str, summary_id: str) -> Optional[Dict]:
        """
        Get a specific summary by ID.
        
        Args:
            user_email: User's email address
            summary_id: Summary document ID
            
        Returns:
            Summary document if found, None otherwise
        """
        try:
            return await self.firestore_service.get_summary_by_id(user_email, summary_id)
        except Exception as e:
            logger.error(f"Error getting summary {summary_id} for user {user_email}: {str(e)}")
            return None