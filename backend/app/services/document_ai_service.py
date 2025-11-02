# Document AI Service for LegalLens
import logging
import io
from typing import Dict, Any, List
from google.cloud import storage
import os
from datetime import datetime

# Text extraction libraries
import fitz  # PyMuPDF
from PIL import Image

# Gemini API
import google.generativeai as genai

# Centralized credentials management
from app.utils.credentials import get_credentials, get_project_id, is_credentials_available

logger = logging.getLogger(__name__)


class DocumentAIService:
    def __init__(self):
        self.project_id = get_project_id() or os.getenv("GCP_PROJECT_ID")
        self.location = os.getenv("DOCUMENT_AI_LOCATION", "us")
        self.processor_id = os.getenv("DOCUMENT_AI_PROCESSOR_ID")
        self.bucket_name = os.getenv("GCS_BUCKET_NAME")
        
        # Initialize Gemini API
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")
        if self.gemini_api_key:
            genai.configure(api_key=self.gemini_api_key)
            self.gemini_model = genai.GenerativeModel('gemini-2.5-flash')
            logger.info("✅ Gemini API configured successfully")
        else:
            self.gemini_model = None
            logger.warning("⚠️  Gemini API key not found in environment variables")
        
        # Initialize with base64 credentials
        if not is_credentials_available():
            logger.warning("❌ No Google Cloud credentials available for Document AI service")
            self.credentials = None
        else:
            self.credentials = get_credentials()
            logger.info("✅ Using base64 encoded service account credentials for Document AI")
        
        if not all([self.project_id, self.processor_id]):
            logger.warning("⚠️  Document AI credentials not fully configured")
        
        self.client = None
        self.storage_client = None
    
    def get_supported_mime_types(self) -> List[str]:
        """Get list of supported MIME types for Document AI processing."""
        return [
            "application/pdf",
            "application/octet-stream",  # Often used for PDFs by some clients
            "image/gif",
            "image/tiff",
            "image/jpeg",
            "image/png",
            "image/bmp",
            "image/webp"
        ]
    
    def _detect_file_type(self, file_content: bytes, mime_type: str) -> str:
        """Detect actual file type from content if MIME type is generic."""
        # Check for PDF signature
        if file_content.startswith(b'%PDF'):
            return "application/pdf"
        
        # Check for common image signatures
        if file_content.startswith(b'\xff\xd8\xff'):
            return "image/jpeg"
        elif file_content.startswith(b'\x89PNG'):
            return "image/png"
        elif file_content.startswith(b'GIF87a') or file_content.startswith(b'GIF89a'):
            return "image/gif"
        elif file_content.startswith(b'BM'):
            return "image/bmp"
        elif file_content.startswith(b'RIFF') and b'WEBP' in file_content[:12]:
            return "image/webp"
        elif file_content.startswith(b'II*\x00') or file_content.startswith(b'MM\x00*'):
            return "image/tiff"
        
        # If no signature detected, return original MIME type
        return mime_type
    
    def _preprocess_image_for_ocr(self, image: Image.Image) -> Image.Image:
        """Preprocess image to improve OCR quality."""
        import numpy as np
        from PIL import ImageEnhance, ImageFilter
        
        try:
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Resize if image is too small (minimum 300 DPI equivalent)
            width, height = image.size
            if width < 1000 or height < 1000:
                scale_factor = max(1000 / width, 1000 / height)
                new_width = int(width * scale_factor)
                new_height = int(height * scale_factor)
                image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
            
            # Enhance contrast
            contrast_enhancer = ImageEnhance.Contrast(image)
            image = contrast_enhancer.enhance(1.5)
            
            # Enhance sharpness
            sharpness_enhancer = ImageEnhance.Sharpness(image)
            image = sharpness_enhancer.enhance(2.0)
            
            # Convert to grayscale for better OCR
            image = image.convert('L')
            
            # Apply threshold to get binary image
            import numpy as np
            img_array = np.array(image)
            
            # Adaptive threshold
            from PIL import Image as PILImage
            threshold = np.mean(img_array)
            binary_array = np.where(img_array > threshold, 255, 0).astype(np.uint8)
            image = PILImage.fromarray(binary_array, mode='L')
            
            # Apply slight blur to smooth edges
            image = image.filter(ImageFilter.MedianFilter(size=3))
            
            return image
            
        except Exception as e:
            logger.warning(f"Image preprocessing failed, using original: {e}")
            return image
    
    def _is_text_concatenated(self, text: str) -> bool:
        """Check if the OCR text appears to be concatenated without proper spacing."""
        if not text or len(text.strip()) < 50:
            return False
        
        lines = text.strip().split('\n')
        concatenated_lines = 0
        
        for line in lines:
            line = line.strip()
            if len(line) < 20:  # Skip short lines
                continue
                
            # Check for patterns that indicate concatenated text
            words = line.split()
            if len(words) <= 2 and len(line) > 50:  # Very long "words"
                concatenated_lines += 1
            
            # Check for lack of spaces in long sequences
            long_sequences = [word for word in words if len(word) > 20]
            if len(long_sequences) > len(words) * 0.3:  # 30% of words are very long
                concatenated_lines += 1
        
        # If more than 30% of substantial lines appear concatenated, the text is likely concatenated
        substantial_lines = [line for line in lines if len(line.strip()) >= 20]
        if substantial_lines and concatenated_lines / len(substantial_lines) > 0.3:
            return True
        
        return False
    
    def _fix_text_spacing(self, text: str) -> str:
        """Apply post-processing to fix spacing issues in OCR text."""
        if not text:
            return text
        
        # Keep original for comparison
        original_text = text
        
        # Split into lines for processing
        lines = text.split('\n')
        fixed_lines = []
        
        for line in lines:
            if not line.strip():
                fixed_lines.append(line)
                continue
            
            # Apply spacing fixes to each line
            fixed_line = self._fix_line_spacing(line)
            fixed_lines.append(fixed_line)
        
        fixed_text = '\n'.join(fixed_lines)
        
        # Log the improvement
        logger.info(f"Text spacing fix - Original length: {len(original_text)}, Fixed length: {len(fixed_text)}")
        
        return fixed_text
    
    def _fix_line_spacing(self, line: str) -> str:
        """Fix spacing issues in a single line of text."""
        import re
        
        if not line.strip():
            return line
        
        # Common patterns to add spaces
        patterns = [
            # Add space before capital letters that follow lowercase letters
            (r'([a-z])([A-Z])', r'\1 \2'),
            
            # Add space after periods if not already there
            (r'\.([A-Z])', r'. \1'),
            
            # Add space after commas if not already there
            (r',([A-Za-z])', r', \1'),
            
            # Add space after colons if not already there
            (r':([A-Za-z])', r': \1'),
            
            # Add space after semicolons if not already there
            (r';([A-Za-z])', r'; \1'),
            
            # Add space between number and letter
            (r'(\d)([A-Za-z])', r'\1 \2'),
            (r'([A-Za-z])(\d)', r'\1 \2'),
            
            # Add space before opening parentheses
            (r'([A-Za-z])\(', r'\1 ('),
            
            # Add space after closing parentheses
            (r'\)([A-Za-z])', r') \1'),
            
            # Fix common word concatenations by detecting capital letters mid-word
            # This is more aggressive and should be used carefully
            (r'([a-z]{2,})([A-Z][a-z]{2,})', r'\1 \2'),
        ]
        
        fixed_line = line
        for pattern, replacement in patterns:
            fixed_line = re.sub(pattern, replacement, fixed_line)
        
        # Clean up multiple spaces
        fixed_line = re.sub(r'\s+', ' ', fixed_line)
        
        return fixed_line.strip()

    async def _extract_text_with_gemini(self, file_content: bytes, mime_type: str) -> str:
        """Extract text from image using Gemini API."""
        try:
            if not self.gemini_model:
                raise Exception("Gemini API not configured")
            
            # Convert bytes to base64 for Gemini API
            import base64
            image_b64 = base64.b64encode(file_content).decode('utf-8')
            
            # Create image part for Gemini
            image_part = {
                "mime_type": mime_type,
                "data": image_b64
            }
            
            # Prompt for text extraction
            prompt = """
            Please extract all text content from this image. The image contains a legal document.
            
            Instructions:
            1. Extract ALL visible text exactly as it appears
            2. Maintain the original formatting and structure
            3. Include headers, footers, and any marginal text
            4. If there are multiple columns, read from left to right, top to bottom
            5. Preserve line breaks and paragraph structure
            6. Include any table content in a readable format
            7. If text is partially obscured or unclear, indicate with [unclear] but attempt to provide your best interpretation
            
            Please provide only the extracted text without any additional commentary or analysis.
            """
            
            # Generate content using Gemini
            response = self.gemini_model.generate_content([prompt, image_part])
            
            if response.text:
                extracted_text = response.text.strip()
                logger.info(f"Gemini API successfully extracted {len(extracted_text)} characters of text")
                return extracted_text
            else:
                logger.warning("Gemini API returned empty response")
                return "No text could be extracted from this image using Gemini API."
                
        except Exception as e:
            logger.error(f"Gemini API text extraction failed: {e}")
            return f"Error extracting text with Gemini API: {str(e)}"

    async def process_document(self, file_content: bytes, mime_type: str) -> Dict[str, Any]:
        """Process document with actual text extraction from PDFs and images."""
        try:
            # Detect actual file type if MIME type is generic
            actual_mime_type = self._detect_file_type(file_content, mime_type)
            logger.info(f"Original MIME type: {mime_type}, Detected type: {actual_mime_type}")
            
            extracted_text = ""
            processing_method = ""

            if actual_mime_type == "application/pdf":
                # Extract text from PDF using PyMuPDF
                processing_method = "pdf_pymupdf"
                try:
                    # Open PDF from bytes
                    pdf_document = fitz.open(stream=file_content, filetype="pdf")
                    
                    # Extract text from all pages
                    all_text = []
                    for page_num in range(pdf_document.page_count):
                        page = pdf_document[page_num]
                        page_text = page.get_text()
                        if page_text.strip():
                            all_text.append(f"=== Page {page_num + 1} ===\n{page_text}")
                    
                    pdf_document.close()
                    
                    if all_text:
                        extracted_text = "\n\n".join(all_text)
                    else:
                        extracted_text = "No text could be extracted from this PDF. The document may contain only images or scanned content."
                        
                except Exception as pdf_error:
                    logger.error(f"PDF text extraction failed: {pdf_error}")
                    extracted_text = f"Error extracting text from PDF: {str(pdf_error)}"
                    
            elif actual_mime_type.startswith("image/"):
                # Use Gemini API for image text extraction
                processing_method = "gemini_api"
                logger.info(f"Processing image file with Gemini API: {actual_mime_type}")
                extracted_text = await self._extract_text_with_gemini(file_content, actual_mime_type)
                
            else:
                processing_method = "unsupported"
                extracted_text = f"Unsupported file type: {actual_mime_type} (original: {mime_type})"
            
            # Add metadata to the extracted text
            full_text = f"Document processed using: {processing_method}\nMIME Type: {actual_mime_type}\nProcessed at: {datetime.now().isoformat()}\n\n{extracted_text}"
            
            # Save extracted text to local file
            text_timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            text_filename = f"extracted_text_{text_timestamp}.txt"
            
            # Create the output folder if it doesn't exist (container-safe path)
            output_dir = os.path.join(os.path.dirname(__file__), "..", "output")
            os.makedirs(output_dir, exist_ok=True)
            
            # Save the extracted text
            output_path = os.path.join(output_dir, text_filename)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(full_text)
            
            logger.info(f"Text extracted and saved to: {output_path}")
            
            return {
                "text": full_text,
                "pages": 1,  # Number of pages as integer
                "entities": [],
                "tables": [],
                "confidence": 0.95 if processing_method in ["pdf_pymupdf", "gemini_api"] else 0.0,
                "processing_method": processing_method,
                "mime_type": actual_mime_type,
                "text_file": text_filename
            }
            
        except Exception as e:
            logger.error(f"Document processing error: {e}")
            raise Exception(f"Failed to process document: {str(e)}")
    
    async def upload_to_storage(self, file_content: bytes, filename: str, user_id: str) -> str:
        """Upload file to Google Cloud Storage."""
        try:
            # Initialize storage client if needed
            if not self.storage_client:
                self.storage_client = storage.Client(
                    project=self.project_id,
                    credentials=self.credentials
                )
            
            # Get bucket
            bucket = self.storage_client.bucket(self.bucket_name)
            
            # Create blob with user-specific path
            blob_name = f"documents/{user_id}/{datetime.utcnow().isoformat()}/{filename}"
            blob = bucket.blob(blob_name)
            
            # Upload file
            blob.upload_from_string(file_content)
            
            # Return public URL
            return f"gs://{self.bucket_name}/{blob_name}"
            
        except Exception as e:
            logger.error(f"Storage upload error: {e}")
            raise Exception(f"Failed to upload to storage: {str(e)}")
    
    def health_check(self) -> Dict[str, Any]:
        try:
            config_status = {
                "project_id_configured": bool(self.project_id),
                "processor_id_configured": bool(self.processor_id),
                "location": self.location,
                "bucket_configured": bool(self.bucket_name),
                "gemini_api_configured": bool(self.gemini_api_key),
                "gemini_model_initialized": bool(self.gemini_model)
            }
            
            return {
                "success": True,
                "service": "Document AI with Gemini",
                "status": "healthy" if config_status["gemini_api_configured"] else "partial",
                "configuration": config_status,
                "supported_methods": ["pdf_pymupdf", "gemini_api"] if config_status["gemini_api_configured"] else ["pdf_pymupdf"]
            }
        except Exception as e:
            return {
                "success": False,
                "service": "Document AI with Gemini",
                "status": "error",
                "error": str(e)
            }


def get_document_ai_service() -> DocumentAIService:
    return DocumentAIService()
