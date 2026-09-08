"""
NIRIKSHAK AI - PaddleOCR Image Extraction Engine.

Extracts text blocks, confidence scores, and 2D bounding boxes from package images.
"""

import os
from dataclasses import dataclass
from typing import Any, List, Optional

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger("services.ocr.ocr_engine")
settings = get_settings()

_paddle_ocr_instance = None


def get_paddle_ocr():
    """Lazy initializer for PaddleOCR engine."""
    global _paddle_ocr_instance
    if _paddle_ocr_instance is None:
        try:
            from paddleocr import PaddleOCR
            logger.info("Initializing PaddleOCR engine...")
            _paddle_ocr_instance = PaddleOCR(
                use_angle_cls=True,
                lang=settings.ocr_language or "en",
                use_gpu=settings.ocr_use_gpu,
                show_log=False,
            )
            logger.info("PaddleOCR engine initialized successfully.")
        except Exception as e:
            logger.warning(f"PaddleOCR failed to initialize: {e}. OCR will operate in fallback mode.")
            _paddle_ocr_instance = False
    return _paddle_ocr_instance if _paddle_ocr_instance is not False else None


@dataclass
class OCRBlock:
    """Structure for an OCR text block with coordinates."""
    text: str
    confidence: float
    bbox: List[List[float]]  # [[x1, y1], [x2, y2], [x3, y3], [x4, y4]]


@dataclass
class OCRResultPayload:
    """Consolidated OCR extraction output."""
    raw_text: str
    processed_text: str
    average_confidence: float
    blocks: List[OCRBlock]
    bounding_boxes_json: List[dict]


class OCREngine:
    """Product packaging OCR extractor."""

    def process_image(self, image_path: str) -> OCRResultPayload:
        """
        Run PaddleOCR on an image file. Applies OpenCV CLAHE pre-processing for improved 
        contrast and text extraction consistency on glossy packages.

        Returns raw text, confidence scores, and bounding boxes.
        """
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found: {image_path}")

        # Pre-process image with OpenCV (CLAHE)
        import cv2
        processed_path = image_path + "_processed.jpg"
        try:
            img = cv2.imread(image_path)
            if img is not None:
                gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
                clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
                enhanced = clahe.apply(gray)
                cv2.imwrite(processed_path, enhanced)
            else:
                processed_path = image_path
        except Exception as e:
            logger.warning(f"OpenCV pre-processing failed, falling back to original: {e}")
            processed_path = image_path

        ocr = get_paddle_ocr()

        blocks: List[OCRBlock] = []
        raw_lines = []
        bboxes_json = []
        total_conf = 0.0

        if ocr:
            try:
                results = ocr.ocr(processed_path, cls=True)
                if results and results[0]:
                    for line in results[0]:
                        bbox, (text, score) = line
                        b = OCRBlock(
                            text=text,
                            confidence=round(float(score), 4),
                            bbox=bbox,
                        )
                        blocks.append(b)
                        raw_lines.append(text)
                        bboxes_json.append({
                            "text": text,
                            "bbox": bbox,
                            "score": round(float(score), 4),
                        })
                        total_conf += float(score)
            except Exception as e:
                logger.error(f"PaddleOCR execution error on {image_path}: {e}")
            finally:
                if processed_path != image_path and os.path.exists(processed_path):
                    os.remove(processed_path)

        raw_text = "\n".join(raw_lines)
        avg_conf = (total_conf / len(blocks)) if blocks else 0.0

        return OCRResultPayload(
            raw_text=raw_text,
            processed_text=raw_text,
            average_confidence=round(avg_conf, 4),
            blocks=blocks,
            bounding_boxes_json=bboxes_json,
        )
