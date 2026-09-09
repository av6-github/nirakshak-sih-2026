"""
NIRIKSHAK AI - Layered Declaration Extraction Service.

Extracts mandatory Legal Metrology product declarations from OCR text using a 3-layer pipeline:
- Layer 1: Regex & Deterministic Extraction
- Layer 2: Schema-based Groq LLM Extraction
- Layer 3: Validation & Field Normalization
"""

import json
import re
from dataclasses import asdict, dataclass
from typing import Any, Dict, Optional

from groq import Groq

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger("services.extraction.declaration_extractor")
settings = get_settings()


@dataclass
class ExtractedDeclarations:
    """Dataclass holding extracted Legal Metrology fields and confidence metadata."""
    manufacturer_name: Optional[str] = None
    packer_name: Optional[str] = None
    importer_name: Optional[str] = None
    generic_product_name: Optional[str] = None
    net_quantity: Optional[float] = None
    unit: Optional[str] = None
    mrp: Optional[float] = None
    currency: str = "INR"
    manufacture_month: Optional[int] = None
    manufacture_year: Optional[int] = None
    consumer_care_name: Optional[str] = None
    consumer_care_phone: Optional[str] = None
    consumer_care_email: Optional[str] = None
    consumer_care_address: Optional[str] = None
    expiry_date: Optional[str] = None
    batch_number: Optional[str] = None
    product_category: str = "Unknown"
    dynamic_fields: Dict[str, Any] = None
    field_confidence: Dict[str, float] = None
    raw_extractions: Dict[str, Any] = None


class DeclarationExtractor:
    """3-Layer Declaration Extractor."""

    def __init__(self):
        self.groq_client = None
        if settings.groq_api_key and settings.groq_api_key != "your_groq_api_key_here":
            try:
                self.groq_client = Groq(api_key=settings.groq_api_key)
            except Exception as e:
                logger.warning(f"Could not initialize Groq client: {e}")

    # =========================================================================
    # LAYER 1: REGEX EXTRACTION
    # =========================================================================
    def extract_layer1_regex(self, text: str) -> Dict[str, Any]:
        """Extract fields using regex patterns."""
        results = {}

        # 1. MRP Extraction
        mrp_match = re.search(
            r"(?i)(?:mrp|rs\.?|₹|max\.?\s*retail\s*price)[\s:]*(?:incl\.?\s*of\s*all\s*taxes)?[\s:]*₹?\s*(\d+(?:\.\d{1,2})?)",
            text,
        )
        if mrp_match:
            try:
                results["mrp"] = float(mrp_match.group(1))
                results["currency"] = "INR"
            except ValueError:
                pass

        # 2. Net Quantity & Unit Extraction
        net_qty_match = re.search(
            r"(?i)(?:net\s*(?:qty|quantity|weight|wt)|content)[\s:]*(\d+(?:\.\d+)?)\s*(g|kg|ml|l|liter|litres|pcs|n|units?)",
            text,
        )
        if net_qty_match:
            try:
                results["net_quantity"] = float(net_qty_match.group(1))
                results["unit"] = net_qty_match.group(2).lower()
            except ValueError:
                pass

        # 3. Manufacture Date (Month / Year)
        date_match = re.search(
            r"(?i)(?:mfd|pkd|mfg|manufactured|packed|date)[\s:]*(\d{1,2})[/.-](\d{2,4})",
            text,
        )
        if date_match:
            try:
                m = int(date_match.group(1))
                y = int(date_match.group(2))
                if y < 100:
                    y += 2000
                if 1 <= m <= 12 and 2000 <= y <= 2030:
                    results["manufacture_month"] = m
                    results["manufacture_year"] = y
            except ValueError:
                pass

        # 4. Consumer Care Email
        email_match = re.search(r"[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}", text)
        if email_match:
            results["consumer_care_email"] = email_match.group(0)

        # 5. Consumer Care Phone
        phone_match = re.search(
            r"(?i)(?:phone|tel|contact|helpline|customer\s*care|call)[\s:]*([+\d\s-]{8,15})",
            text,
        )
        if phone_match:
            phone_str = phone_match.group(1).strip()
            if len(re.sub(r"\D", "", phone_str)) >= 8:
                results["consumer_care_phone"] = phone_str

        # 6. Batch / Lot Number Extraction
        batch_match = re.search(
            r"(?i)(?:b\.?\s*no\.?|batch\s*(?:no\.?|number|#)?|lot\s*(?:no\.?|#)?)[\s:]*([A-Za-z0-9\/-]+)",
            text,
        )
        if batch_match:
            b_val = batch_match.group(1).strip()
            if len(b_val) >= 2 and not b_val.lower().startswith("date"):
                results["batch_number"] = b_val

        return results

    # =========================================================================
    # LAYER 2: GROQ LLM SCHEMA EXTRACTION
    # =========================================================================
    def extract_layer2_llm(self, text: str) -> Dict[str, Any]:
        """Extract structured declarations using Groq Llama 3.1 LLM."""
        if not self.groq_client:
            logger.info("Groq API key not set or invalid; skipping LLM extraction layer.")
            return {}

        prompt = f"""
You are an expert Legal Metrology compliance extraction AI.
Analyze the following OCR text extracted from product packaging. 

Your task is to identify the Product Category and dynamically extract ALL factual product declarations and fields present.

CRITICAL INSTRUCTIONS:
1. Product Category: Identify the product type (e.g., "Food", "Cosmetics", "Book", "Electronics").
2. Dynamic Field Extraction: Extract ALL relevant declarations. Do not limit yourself to a predefined list.
3. Standardized Naming: IF APPLICABLE, you MUST use these exact keys: manufacturer_name, packer_name, importer_name, generic_product_name, net_quantity, unit, mrp, manufacture_month, manufacture_year, expiry_date, consumer_care_name, consumer_care_phone, consumer_care_email, consumer_care_address, batch_number.
4. Cross-Image Logic Deduction: Logically merge information split across labels.

CRITICAL EDGE CASES & FEW-SHOT EXAMPLES:

A. MRP (Maximum Retail Price) Edge Cases:
- The MRP MUST be the highest absolute currency value for the entire pack.
- IGNORE unit-based pricing or piece counts. 
- Example: "MRP Rs. 164.00 (per 10 capsules)" -> You MUST extract `164.00`, NOT `10`.
- Example: "₹ 50.00 / 100g" -> You MUST extract `50.00`.
- Example: "Incl. of all taxes Rs 250" -> You MUST extract `250`.

B. Complex Date Formats & Relative Expiry:
- The keys `manufacture_month` and `manufacture_year` MUST be integers. `expiry_date` MUST be a string (ISO `YYYY-MM`).
- Example: "Mfg 10/24" -> "manufacture_month": 10, "manufacture_year": 2024
- Example: "FEB 26" -> "manufacture_month": 2, "manufacture_year": 2026
- Example: "B.No. A123 M.D. 11/2023" -> "manufacture_month": 11, "manufacture_year": 2023
- RELATIVE EXPIRY: If expiry is relative, calculate the absolute date based on Mfg Date.
- Example: If Mfg is "10/24" and Expiry is "Best before 12 Months from manufacture", calculate and return "expiry_date": "2025-10".
- Example: "JUL 27" -> "expiry_date": "2027-07"
- JOINED DATES: If multiple dates are printed on one line (e.g. "Mfg: FEB. 26; JUL. 27" with a blank Exp label), the first is Mfg and the second is Exp!
- Example: "FEB. 26; JUL. 27" -> "manufacture_month": 2, "manufacture_year": 2026, "expiry_date": "2027-07"

C. OCR Typos & Misspellings:
- OCR often misreads characters. You MUST be lenient and infer the correct meaning.
- Example: "Customer Care nop. 1800-123" -> This is a typo for "no." You MUST extract "consumer_care_phone": "1800-123".
- If you see anything resembling a phone number near "Customer Care" (even with typos like "nop", "n0.", "cstmr"), extract it as `consumer_care_phone`.

Return ONLY a valid JSON object in this exact format (use null if a specific field is entirely missing, but do not include it if it's completely irrelevant):
{{
  "product_category": "string",
  "extracted_fields": {{
    "key": "value"
  }}
}}

OCR TEXT TO PROCESS:
\"\"\"
{text}
\"\"\"
"""
        try:
            candidate_models = [settings.llm_model, "groq/compound-mini", "groq/compound", "openai/gpt-oss-120b", "openai/gpt-oss-20b"]
            models_to_try = [m for m in dict.fromkeys(candidate_models) if m]
            content = None

            for model_name in models_to_try:
                try:
                    chat_completion = self.groq_client.chat.completions.create(
                        messages=[
                            {"role": "system", "content": "You are a precise JSON extraction engine. Respond with raw JSON only."},
                            {"role": "user", "content": prompt},
                        ],
                        model=model_name,
                        temperature=0.0,
                        response_format={"type": "json_object"},
                    )
                    content = chat_completion.choices[0].message.content
                    if content:
                        break
                except Exception as me:
                    logger.warning(f"Groq model {model_name} failed in declaration_extractor: {me}")

            if not content:
                return {}

            parsed = json.loads(content)
            logger.info("Groq LLM extraction succeeded.")
            return parsed
        except Exception as e:
            logger.error(f"Groq LLM extraction error: {e}")
            return {}

    # =========================================================================
    # LAYER 3: VALIDATION & MERGING PIPELINE
    # =========================================================================
    def extract_declarations(self, ocr_text: str) -> ExtractedDeclarations:
        """
        Execute full 3-layer extraction pipeline.
        Merges regex, LLM extractions, and applies validation rules.
        """
        l1 = self.extract_layer1_regex(ocr_text)
        l2_raw = self.extract_layer2_llm(ocr_text)
        
        l2 = l2_raw.get("extracted_fields", l2_raw) if isinstance(l2_raw, dict) else {}
        product_category = l2_raw.get("product_category", "Unknown") if isinstance(l2_raw, dict) else "Unknown"

        # Merge strategy: Regex takes precedence for precise numeric fields (MRP, Date, Email); LLM fills names & text
        merged = {}
        confidence_scores = {}

        fields = [
            "manufacturer_name", "packer_name", "importer_name",
            "generic_product_name", "net_quantity", "unit", "mrp", "currency",
            "manufacture_month", "manufacture_year", "expiry_date", "batch_number",
            "consumer_care_name", "consumer_care_phone",
            "consumer_care_email", "consumer_care_address",
        ]

        for field in fields:
            val = l1.get(field) or l2.get(field)
            if val is not None:
                merged[field] = val
                # Calculate field confidence
                if field in l1 and field in l2:
                    confidence_scores[field] = 0.95
                elif field in l1:
                    confidence_scores[field] = 0.90
                else:
                    confidence_scores[field] = 0.80
            else:
                merged[field] = None
                confidence_scores[field] = 0.0

        # Layer 3 Normalizations
        if merged.get("mrp") is not None:
            try:
                merged["mrp"] = float(merged["mrp"])
                if merged["mrp"] <= 0:
                    merged["mrp"] = None
            except (ValueError, TypeError):
                merged["mrp"] = None

        if merged.get("net_quantity") is not None:
            try:
                merged["net_quantity"] = float(merged["net_quantity"])
            except (ValueError, TypeError):
                merged["net_quantity"] = None

        # Handle LLM outputting manufacture_date string instead of separate integers
        if not merged.get("manufacture_month") and not merged.get("manufacture_year"):
            mfg_date_str = l2.get("manufacture_date") or l2.get("mfg_date") or l2.get("manufactured_date")
            if mfg_date_str and isinstance(mfg_date_str, str):
                date_match = re.search(r"(\d{4})[-/.](\d{1,2})|(\d{1,2})[-/.](\d{2,4})", mfg_date_str)
                if date_match:
                    try:
                        if date_match.group(1): # YYYY-MM
                            merged["manufacture_year"] = int(date_match.group(1))
                            merged["manufacture_month"] = int(date_match.group(2))
                        else: # MM-YYYY
                            m = int(date_match.group(3))
                            y = int(date_match.group(4))
                            merged["manufacture_month"] = m
                            merged["manufacture_year"] = y if y >= 100 else y + 2000
                    except (ValueError, TypeError):
                        pass

        unit_str = str(merged.get("unit") or "").lower().strip()
        if unit_str in ["liter", "litres", "ltr"]:
            merged["unit"] = "l"
        elif unit_str in ["grams", "gm"]:
            merged["unit"] = "g"
        elif unit_str in ["kilogram", "kgs"]:
            merged["unit"] = "kg"
        elif unit_str in ["milliliter", "mls"]:
            merged["unit"] = "ml"

        return ExtractedDeclarations(
            manufacturer_name=merged.get("manufacturer_name"),
            packer_name=merged.get("packer_name"),
            importer_name=merged.get("importer_name"),
            generic_product_name=merged.get("generic_product_name"),
            net_quantity=merged.get("net_quantity"),
            unit=merged.get("unit"),
            mrp=merged.get("mrp"),
            currency=merged.get("currency") or "INR",
            manufacture_month=merged.get("manufacture_month"),
            manufacture_year=merged.get("manufacture_year"),
            consumer_care_name=merged.get("consumer_care_name"),
            consumer_care_phone=merged.get("consumer_care_phone"),
            consumer_care_email=merged.get("consumer_care_email"),
            consumer_care_address=merged.get("consumer_care_address"),
            expiry_date=merged.get("expiry_date"),
            batch_number=merged.get("batch_number"),
            product_category=product_category,
            dynamic_fields=l2,
            field_confidence=confidence_scores,
            raw_extractions={"regex": l1, "llm": l2_raw},
        )
