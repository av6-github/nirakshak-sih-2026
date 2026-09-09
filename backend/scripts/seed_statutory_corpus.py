"""
NIRIKSHAK AI - Statutory Corpus ChromaDB Ingestion Script.

Indexes core Legal Metrology Act, 2009 and Legal Metrology (Packaged Commodities) Rules, 2011
sections and rules into ChromaDB with explicit rule IDs and statutory text.
"""

import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.logging import setup_logging
from app.services.rag.chroma_service import ChromaService
from app.services.rag.parser import LegalChunk
from app.services.rag.violation_analyzer import STATUTORY_DEFAULTS

logger = setup_logging("scripts.seed_statutory_corpus")

CORE_STATUTORY_CHUNKS = [
    {
        "chunk_id": "act2009_sec36_penalty_noncompliant_packaging",
        "document_id": "legal_metrology_act_2009",
        "document_name": "Legal Metrology Act, 2009 (Act No. 1 of 2010)",
        "document_type": "primary_act",
        "page_number": 14,
        "rule_id": "SECTION-36",
        "section": "Section 36: Penalty for selling, etc., of non-standard packages",
        "title": "Penalty for Non-Standard Packages and False Declarations",
        "content": (
            "Section 36 of the Legal Metrology Act, 2009:\n"
            "(1) Whoever manufactures, packs, imports, sells, distributes, delivers or offers or exposes "
            "for sale any pre-packaged commodity which does not conform to the declarations on the package "
            "as provided in this Act or the rules made thereunder, shall be punished with fine which may "
            "extend to twenty-five thousand rupees (₹25,000) for the first offence, for the second offence "
            "to fifty thousand rupees (₹50,000) and for the subsequent offence to one lakh rupees (₹1,00,000) "
            "or with imprisonment for a term which may extend to one year or with both.\n"
            "(2) Whoever manufactures or packs or imports or causes to be manufactured or packed or imported "
            "any pre-packaged commodity with error in net quantity beyond the maximum permissible error "
            "shall be punished with fine not less than ten thousand rupees (₹10,000) but which may extend to "
            "fifty thousand rupees (₹50,000) and for the second offence with fine which may extend to one lakh "
            "rupees or with imprisonment for a term which may extend to one year or with both."
        ),
    },
    {
        "chunk_id": "act2009_sec15_power_inspection_seizure",
        "document_id": "legal_metrology_act_2009",
        "document_name": "Legal Metrology Act, 2009",
        "document_type": "primary_act",
        "page_number": 8,
        "rule_id": "SECTION-15",
        "section": "Section 15: Power of inspection, search, seizure and forfeiture",
        "title": "Power of Legal Metrology Officer to Inspect and Seize Non-Compliant Packages",
        "content": (
            "Section 15 of Legal Metrology Act, 2009:\n"
            "The Director, Controller or any legal metrology officer may, if he has any reason to believe "
            "that any weight or measure or any pre-packaged commodity is being manufactured, packed, kept, "
            "stored, offered for sale or distributed in contravention of this Act or the rules made thereunder, "
            "enter at all reasonable times any premises and inspect, search and seize any such weight, measure, "
            "package, commodity, record, register or document. Non-compliant pre-packaged commodities are "
            "liable to immediate confiscation and seizure."
        ),
    },
    {
        "chunk_id": "act2009_sec18_declarations_prepackaged_commodities",
        "document_id": "legal_metrology_act_2009",
        "document_name": "Legal Metrology Act, 2009",
        "document_type": "primary_act",
        "page_number": 9,
        "rule_id": "SECTION-18",
        "section": "Section 18: Declarations on pre-packaged commodities",
        "title": "Mandatory Requirement of Declarations on Packages",
        "content": (
            "Section 18 of Legal Metrology Act, 2009:\n"
            "(1) No person shall manufacture, pack, sell, import, distribute, deliver, offer, expose or "
            "have in his possession for sale any pre-packaged commodity, unless such package is in such "
            "standard quantities or number and bears thereon such declarations and markings in such manner "
            "as may be prescribed.\n"
            "(2) Any advertisement mentioning the retail sale price of a pre-packaged commodity shall "
            "contain a declaration as to the net quantity or number of the commodity contained in the package."
        ),
    },
    {
        "chunk_id": "pcr2011_rule6_mandatory_declarations_pdp",
        "document_id": "lmpc_rules_2011",
        "document_name": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "document_type": "statutory_rule",
        "page_number": 4,
        "rule_id": "RULE-LM-001",
        "section": "Rule 6: Declarations to be made on every package",
        "title": "Principal Display Panel Mandatory Declarations",
        "content": (
            "Rule 6(1) of the Legal Metrology (Packaged Commodities) Rules, 2011:\n"
            "Every package shall bear thereon or on label securely affixed thereto, a definite, plain and "
            "conspicuous declaration made in accordance with the provisions of this Chapter:\n"
            "(a) The name and address of the manufacturer, or where the manufacturer is not the packer, "
            "the name and address of the manufacturer and packer, or importer;\n"
            "(b) The common or generic name of the commodity contained in the package;\n"
            "(c) The net quantity, in terms of the standard unit of weight or measure, of the commodity;\n"
            "(d) The retail sale price of the package in the form: 'Maximum or Max. retail price Rs. ... "
            "inclusive of all taxes' or 'MRP Rs. ... incl. of all taxes';\n"
            "(e) Where a commodity is packed in standard sizes, the unit sale price in Rupees per g, ml, kg, or litre;\n"
            "(f) The month and year in which the commodity is manufactured or pre-packed or imported;\n"
            "(g) The name, address, telephone number and e-mail address of the person or office for consumer complaints."
        ),
    },
    {
        "chunk_id": "pcr2011_rule18_mrp_overcharging_prohibition",
        "document_id": "lmpc_rules_2011",
        "document_name": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "document_type": "statutory_rule",
        "page_number": 12,
        "rule_id": "RULE-LM-018",
        "section": "Rule 18(2): Prohibition of sale at price higher than MRP",
        "title": "Strict Prohibition on Overcharging Beyond Printed MRP",
        "content": (
            "Rule 18(2) of the Legal Metrology (Packaged Commodities) Rules, 2011:\n"
            "No retail dealer or other person including manufacturer, packer, importer or e-commerce entity "
            "shall make any sale of any commodity in packed form at a price exceeding the retail sale price "
            "(MRP) declared on the package, carton, or label.\n"
            "Dual MRP Prohibition: No manufacturer, packer, or importer shall declare different maximum retail "
            "prices on an identical pre-packaged commodity.\n"
            "Penalties for Overcharging: Violation of Rule 18(2) is an offence under Section 36 of the Legal "
            "Metrology Act, 2009, punishable with a compounding fee or fine up to ₹25,000 for first offence, "
            "up to ₹50,000 for second offence, and possible prosecution."
        ),
    },
    {
        "chunk_id": "pcr2011_rule11_net_quantity_units",
        "document_id": "lmpc_rules_2011",
        "document_name": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "document_type": "statutory_rule",
        "page_number": 8,
        "rule_id": "RULE-LM-002",
        "section": "Rule 11 & 13: Units of weight, measure or number and font size",
        "title": "Standard Metric Units for Net Quantity & Font Area Requirements",
        "content": (
            "Rules 11, 12, and 13 of the Legal Metrology (Packaged Commodities) Rules, 2011:\n"
            "1. Measurement Units: The declaration of net quantity must be expressed only in standard metric units:\n"
            "- Weight: gram (g), kilogram (kg)\n"
            "- Volume: millilitre (ml), litre (l)\n"
            "- Length: millimetre (mm), centimetre (cm), metre (m)\n"
            "- Area: square metre (sq m)\n"
            "- Count: number (N or U)\n"
            "2. Non-metric units like pounds, ounces, inches, or fluid ounces are strictly illegal as sole declarations.\n"
            "3. Font Size: Net quantity numerals and letters must meet minimum height thresholds based on the area of "
            "the Principal Display Panel (PDP), ranging from 1.0 mm for small packs up to 6.0 mm for packs exceeding 1 kg/litre."
        ),
    },
    {
        "chunk_id": "pcr2011_rule27_registration_manufacturers_packers",
        "document_id": "lmpc_rules_2011",
        "document_name": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "document_type": "statutory_rule",
        "page_number": 16,
        "rule_id": "RULE-LM-027",
        "section": "Rule 27: Registration of Manufacturers, Packers and Importers",
        "title": "Mandatory Registration with Legal Metrology Controller",
        "content": (
            "Rule 27 of the Legal Metrology (Packaged Commodities) Rules, 2011:\n"
            "Every individual, firm, Hindu undivided family, society, company or corporation who pre-packs "
            "or imports any commodity for sale, distribution or delivery shall make an application to the "
            "Director or Controller of Legal Metrology for registration of his name and complete address "
            "within ninety days from the commencement of packing.\n"
            "Failure to obtain registration under Rule 27 is an offence punishable under Section 36 and Rule 32."
        ),
    },
    {
        "chunk_id": "pcr2011_rule32_penalty_general",
        "document_id": "lmpc_rules_2011",
        "document_name": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "document_type": "statutory_rule",
        "page_number": 19,
        "rule_id": "RULE-LM-032",
        "section": "Rule 32: Penalty for contravention of Rules",
        "title": "General Penalty Clause for Violations of Packaging Rules",
        "content": (
            "Rule 32 of Legal Metrology (Packaged Commodities) Rules, 2011:\n"
            "Whoever contravenes any provision of these rules, for which no punishment is provided under "
            "the Legal Metrology Act, 2009, shall be punished with fine which may extend to five thousand rupees (₹5,000).\n"
            "Compounding of Offences under Section 48: First offences for packaging violations may be compounded "
            "by the Legal Metrology Controller upon payment of statutory compounding fees."
        ),
    },
    {
        "chunk_id": "pcr2011_ecommerce_country_of_origin_mandate",
        "document_id": "lmpc_amendment_ecommerce",
        "document_name": "Legal Metrology E-Commerce Amendments",
        "document_type": "amendment",
        "page_number": 1,
        "rule_id": "RULE-LM-010",
        "section": "Rule 6(10): Mandatory Declarations on E-Commerce Platforms",
        "title": "E-Commerce Marketplaces Mandatory Country of Origin & Digital Declarations",
        "content": (
            "Rule 6(10) of the Legal Metrology (Packaged Commodities) Rules, 2011:\n"
            "An e-commerce entity shall display on the digital network or marketplace platform all mandatory "
            "declarations specified under Rule 6(1), including:\n"
            "1. Name and address of manufacturer/packer/importer\n"
            "2. Common or generic name\n"
            "3. Net quantity\n"
            "4. Maximum Retail Price (MRP) and Unit Sale Price\n"
            "5. Country of Origin (mandatory for all domestic and imported goods)\n"
            "6. Expiry or Best Before date\n"
            "7. Consumer care details\n"
            "Marketplaces and sellers failing to display these declarations on product listing pages are "
            "liable to legal notices and penalties under Section 36 of the Act."
        ),
    },
]

def main():
    logger.info("Starting ingestion of Core Statutory Corpus into ChromaDB...")
    chroma = ChromaService()

    chunks_to_upsert: list[LegalChunk] = []

    # 1. Add core statutory chunks
    for sc in CORE_STATUTORY_CHUNKS:
        chunks_to_upsert.append(
            LegalChunk(
                chunk_id=sc["chunk_id"],
                document_id=sc["document_id"],
                document_name=sc["document_name"],
                document_type=sc["document_type"],
                page_number=sc["page_number"],
                rule_id=sc["rule_id"],
                section=sc["section"],
                title=sc["title"],
                content=sc["content"],
                language="en",
                metadata={
                    "rule_id": sc["rule_id"],
                    "document_id": sc["document_id"],
                    "document_name": sc["document_name"],
                    "document_type": sc["document_type"],
                    "page_number": sc["page_number"],
                    "section": sc["section"],
                    "title": sc["title"],
                },
            )
        )

    # 2. Add STATUTORY_DEFAULTS entries as explicit chunks
    for rule_id, data in STATUTORY_DEFAULTS.items():
        chunk_content = (
            f"Statutory Standard for {rule_id} ({data['rule_code']}):\n"
            f"Rule Title: {data['rule_title']}\n"
            f"Authority: {data['act_name']}\n"
            f"Statutory Provision: {data['legal_quote']}\n"
            f"Violation Standard: {data['reason']}\n"
            f"Statutory Penalty: {data['penalty']}"
        )
        chunks_to_upsert.append(
            LegalChunk(
                chunk_id=f"statutory_{rule_id.lower()}",
                document_id="statutory_defaults",
                document_name="LMPC Statutory Rules & Penalty Code",
                document_type="statutory_standard",
                page_number=1,
                rule_id=rule_id,
                section=data["rule_code"],
                title=data["rule_title"],
                content=chunk_content,
                language="en",
                metadata={
                    "rule_id": rule_id,
                    "rule_code": data["rule_code"],
                    "document_id": "statutory_defaults",
                    "document_name": "LMPC Statutory Rules & Penalty Code",
                    "document_type": "statutory_standard",
                    "title": data["rule_title"],
                },
            )
        )

    count = chroma.add_legal_chunks(chunks_to_upsert)
    total_docs = chroma.count_documents()
    logger.info(f"Successfully upserted {count} core statutory chunks. Total ChromaDB documents: {total_docs}")

if __name__ == "__main__":
    main()
