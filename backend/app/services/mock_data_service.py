"""
Mock Data Service for Testing
============================
Provides predefined mock summaries for the test account new@gmail.com
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import random

logger = logging.getLogger(__name__)

class MockDataService:
    """Service for managing mock data for test accounts."""
    
    # Test account email
    TEST_ACCOUNT_EMAIL = "new@gmail.com"
    
    # Predefined mock summaries for the test account
    MOCK_SUMMARIES = [
        {
            "document_title": "Commercial Lease Agreement",
            "original_text": """
This Commercial Lease Agreement is entered into between ABC Properties (Landlord) and Tech Innovations LLC (Tenant) for the lease of office space located at 123 Business Center, Suite 456. The lease term is for three (3) years commencing January 1, 2024, with a monthly rent of $4,500 payable on the first of each month. The tenant shall use the premises solely for general office purposes and software development activities. The landlord shall maintain the building structure, roof, and common areas, while the tenant is responsible for interior maintenance and utilities. Security deposit of $9,000 is required upon signing. Either party may terminate this agreement with 90 days written notice after the first year.
            """,
            "simplified_text": """
This is a lease agreement between ABC Properties (the landlord) and Tech Innovations LLC (the tenant) for office space at 123 Business Center, Suite 456.

Key terms:
- Lease period: 3 years starting January 1, 2024
- Monthly rent: $4,500 due on the 1st of each month
- Permitted use: Office work and software development only
- Landlord responsibilities: Building structure, roof, common areas
- Tenant responsibilities: Interior maintenance and utilities
- Security deposit: $9,000 required at signing
- Early termination: Either party can end the lease with 90 days notice after the first year

This means the tenant will pay $4,500 every month for office space and can use it only for business purposes. The landlord takes care of major building issues while the tenant handles day-to-day maintenance inside their space.
            """,
            "extracted_terms": [
                {
                    "term": "Security Deposit",
                    "definition": "A refundable payment held by the landlord to cover potential damages or unpaid rent",
                    "importance": "high",
                    "explanation": "Protects landlord interests and establishes tenant financial commitment"
                },
                {
                    "term": "Common Areas",
                    "definition": "Shared spaces in a building like lobbies, hallways, and parking areas",
                    "importance": "medium", 
                    "explanation": "Defines which areas are shared and who maintains them"
                },
                {
                    "term": "Use Restriction",
                    "definition": "Limitations on how the leased property can be used",
                    "importance": "high",
                    "explanation": "Prevents tenant from using space for unauthorized activities"
                }
            ],
            "processing_status": "completed",
            "terms_count": 3,
            "spanner_matches": 15,
            "gemini_fallbacks": 2
        },
        {
            "document_title": "Employment Contract",
            "original_text": """
This Employment Agreement is between Global Tech Solutions Inc. and Sarah Johnson for the position of Senior Software Developer. Employment begins March 15, 2024, with an annual salary of $95,000 paid bi-weekly. The employee is entitled to 20 days paid vacation, 10 sick days, and comprehensive health insurance with 80% employer coverage. Work schedule is Monday-Friday, 9 AM to 5 PM, with flexibility for remote work up to 3 days per week. The employee agrees to maintain confidentiality of proprietary information and assigns all work-related intellectual property to the company. Termination requires 2 weeks notice from either party. Non-compete clause restricts working for direct competitors within 50 miles for 12 months post-employment.
            """,
            "simplified_text": """
This is an employment contract between Global Tech Solutions Inc. and Sarah Johnson for a Senior Software Developer position.

Employment details:
- Start date: March 15, 2024
- Salary: $95,000 per year paid every two weeks
- Benefits: 20 vacation days, 10 sick days, health insurance (company pays 80%)
- Schedule: Monday to Friday, 9 AM to 5 PM, can work from home up to 3 days per week
- Confidentiality: Must keep company information secret
- Intellectual property: All work-related creations belong to the company
- Termination: Either party needs to give 2 weeks notice
- Non-compete: Cannot work for competing companies within 50 miles for 12 months after leaving

This means Sarah will earn $95,000 annually with good benefits and flexible work options, but must protect company secrets and cannot immediately join competitors after leaving.
            """,
            "extracted_terms": [
                {
                    "term": "Non-Compete Clause",
                    "definition": "Contract provision restricting employee from working for competitors after leaving",
                    "importance": "high",
                    "explanation": "Limits future employment options but protects company interests"
                },
                {
                    "term": "Intellectual Property Assignment", 
                    "definition": "Transfer of ownership of creative work from employee to employer",
                    "importance": "high",
                    "explanation": "Company owns all work-related inventions and creations"
                },
                {
                    "term": "Confidentiality Agreement",
                    "definition": "Promise to keep company information secret",
                    "importance": "medium",
                    "explanation": "Protects trade secrets and sensitive business information"
                }
            ],
            "processing_status": "completed",
            "terms_count": 3,
            "spanner_matches": 12,
            "gemini_fallbacks": 1
        },
        {
            "document_title": "Service Agreement",
            "original_text": """
This Service Agreement is between Creative Web Studio LLC (Service Provider) and Mountain View Restaurant (Client) for website development services. The project includes designing and developing a responsive restaurant website with online ordering capabilities, menu management system, and customer reservation portal. Total project cost is $12,500 with payment schedule: 50% deposit ($6,250) upon signing, 25% ($3,125) at design approval, and final 25% ($3,125) upon project completion. Timeline is 8 weeks from start date. The service provider retains intellectual property rights to the code framework, while the client owns all custom content and branding elements. Warranty period of 90 days covers bug fixes and minor adjustments. Additional features or changes beyond scope will be billed at $125/hour.
            """,
            "simplified_text": """
This is a service agreement between Creative Web Studio LLC and Mountain View Restaurant for building a restaurant website.

Project details:
- Services: Responsive website with online ordering, menu management, and reservation system
- Total cost: $12,500
- Payment plan: $6,250 upfront, $3,125 when design is approved, $3,125 when finished
- Timeline: 8 weeks to complete
- Ownership: Developer keeps the code framework, restaurant owns their content and branding
- Warranty: 90 days of free bug fixes and small changes
- Extra work: $125 per hour for additional features not originally planned

This means the restaurant will get a complete website for $12,500 paid in three installments, with 90 days of support included. Any extra features will cost additional hourly fees.
            """,
            "extracted_terms": [
                {
                    "term": "Intellectual Property Rights",
                    "definition": "Legal ownership of creative and intellectual work",
                    "importance": "high",
                    "explanation": "Determines who owns the website code versus content"
                },
                {
                    "term": "Scope of Work",
                    "definition": "Detailed description of what work will be performed",
                    "importance": "high",
                    "explanation": "Prevents disputes about what is included in the project"
                },
                {
                    "term": "Warranty Period",
                    "definition": "Time frame during which the service provider fixes defects at no charge",
                    "importance": "medium",
                    "explanation": "Guarantees quality and provides post-delivery support"
                }
            ],
            "processing_status": "completed",
            "terms_count": 3,
            "spanner_matches": 18,
            "gemini_fallbacks": 0
        },
        {
            "document_title": "Purchase Agreement",
            "original_text": """
This Purchase Agreement is between Office Solutions Inc. (Seller) and Dynamic Marketing Agency (Buyer) for the sale of office equipment including 10 ergonomic desk chairs, 5 standing desks, 2 conference tables, and 1 projector system. Total purchase price is $8,750 with delivery included within 15 business days to 789 Corporate Plaza. Payment terms are net 30 days from invoice date. All items come with manufacturer's warranty: chairs 5 years, desks 3 years, tables 2 years, projector 1 year. Seller guarantees all equipment is new and free from defects. Buyer has 7 days from delivery to inspect and report any issues. Return policy allows full refund within 30 days for unused items in original packaging. Installation service available for additional $500.
            """,
            "simplified_text": """
This is a purchase agreement between Office Solutions Inc. and Dynamic Marketing Agency for office equipment.

Purchase details:
- Items: 10 office chairs, 5 standing desks, 2 conference tables, 1 projector system
- Total price: $8,750 including delivery
- Delivery: Within 15 business days to 789 Corporate Plaza
- Payment: Due 30 days after receiving invoice
- Warranties: Chairs 5 years, desks 3 years, tables 2 years, projector 1 year
- Quality guarantee: All items are new and defect-free
- Inspection period: 7 days to report problems after delivery
- Returns: Full refund within 30 days if items are unused and in original packaging
- Installation: Available for extra $500

This means the company will receive $8,750 worth of office equipment with various warranty periods and has one week to check everything after delivery. They have 30 days to pay and can return unused items within 30 days.
            """,
            "extracted_terms": [
                {
                    "term": "Net Payment Terms",
                    "definition": "Payment is due within specified days from invoice date",
                    "importance": "medium",
                    "explanation": "Net 30 means payment is due 30 days after receiving invoice"
                },
                {
                    "term": "Manufacturer Warranty",
                    "definition": "Guarantee from the original manufacturer covering defects and repairs",
                    "importance": "medium",
                    "explanation": "Provides protection beyond the seller guarantees"
                },
                {
                    "term": "Inspection Period",
                    "definition": "Time allowed for buyer to examine goods and report problems",
                    "importance": "high",
                    "explanation": "Limited time to identify and report defects or damages"
                }
            ],
            "processing_status": "completed",
            "terms_count": 3,
            "spanner_matches": 10,
            "gemini_fallbacks": 1
        }
    ]
    
    @classmethod
    def is_test_account(cls, email: str) -> bool:
        """Check if the email is the test account."""
        return email.lower() == cls.TEST_ACCOUNT_EMAIL.lower()
    
    @classmethod
    def get_mock_summary(cls, document_title: Optional[str] = None) -> Dict:
        """
        Get a mock summary for the test account.
        
        Args:
            document_title: Optional title to find specific summary
            
        Returns:
            Mock summary data
        """
        if document_title:
            # Try to find summary with matching title
            for summary in cls.MOCK_SUMMARIES:
                if document_title.lower() in summary["document_title"].lower():
                    return cls._add_timestamps(summary.copy())
        
        # Return random summary if no title match
        summary = random.choice(cls.MOCK_SUMMARIES).copy()
        return cls._add_timestamps(summary)
    
    @classmethod
    def get_all_mock_summaries(cls) -> List[Dict]:
        """Get all mock summaries for the test account."""
        summaries = []
        for i, summary in enumerate(cls.MOCK_SUMMARIES):
            mock_summary = cls._add_timestamps(summary.copy())
            # Vary the timestamps to show different dates
            mock_summary["created_at"] = datetime.utcnow() - timedelta(days=i*2)
            mock_summary["updated_at"] = mock_summary["created_at"]
            summaries.append(mock_summary)
        return summaries
    
    @classmethod
    def _add_timestamps(cls, summary: Dict) -> Dict:
        """Add timestamp and user information to summary."""
        now = datetime.utcnow()
        summary.update({
            "created_at": now,
            "updated_at": now,
            "user_email": cls.TEST_ACCOUNT_EMAIL,
            "id": f"mock_{random.randint(100000, 999999)}"
        })
        return summary
    
    @classmethod
    def generate_processing_response(cls) -> Dict:
        """Generate a realistic processing response for the test account."""
        return {
            "status": "success",
            "message": "Document processed successfully",
            "user_email": cls.TEST_ACCOUNT_EMAIL,
            "processing_time": round(random.uniform(2.5, 4.8), 2),
            "extraction_method": "OCR + AI Analysis",
            "confidence_score": round(random.uniform(0.92, 0.98), 3)
        }
    
    @staticmethod
    def format_response(response_text: str) -> str:
        """
        Format the response to remove unwanted characters and improve readability
        """
        import re
        
        # Remove all asterisks (*) completely
        formatted_text = re.sub(r'\*+', '', response_text)
        
        # Remove emojis (Unicode ranges for common emojis)
        emoji_pattern = re.compile("["
                                 u"\U0001F600-\U0001F64F"  # emoticons
                                 u"\U0001F300-\U0001F5FF"  # symbols & pictographs
                                 u"\U0001F680-\U0001F6FF"  # transport & map symbols
                                 u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
                                 u"\U00002702-\U000027B0"  # dingbats
                                 u"\U000024C2-\U0001F251"
                                 "]+", flags=re.UNICODE)
        formatted_text = emoji_pattern.sub('', formatted_text)
        
        # Remove "Analyze Summary" or similar phrases
        formatted_text = re.sub(r'analyze\s+summary:?\s*', '', formatted_text, flags=re.IGNORECASE)
        formatted_text = re.sub(r'summary\s+analysis:?\s*', '', formatted_text, flags=re.IGNORECASE)
        
        # Clean up extra whitespace and line breaks
        formatted_text = re.sub(r'\n\s*\n\s*\n+', '\n\n', formatted_text)  # Multiple line breaks to double
        formatted_text = re.sub(r'[ \t]+', ' ', formatted_text)  # Multiple spaces to single
        formatted_text = re.sub(r'^\s+', '', formatted_text, flags=re.MULTILINE)  # Leading spaces on lines
        
        return formatted_text.strip()