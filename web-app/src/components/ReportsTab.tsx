'use client';

import React, { useState } from 'react';
import { Complaint, ScanItem } from '../types';
import { OfficerApi } from '../services/api';
import { 
  FileCheck2, 
  Download, 
  ShieldCheck, 
  Fingerprint, 
  Scale,
  AlertTriangle
} from 'lucide-react';

interface ReportsTabProps {
  complaints: Complaint[];
  scans: ScanItem[];
}

export const ReportsTab: React.FC<ReportsTabProps> = ({ complaints, scans }) => {
  const [selectedScanId, setSelectedScanId] = useState<string>(scans[0]?.scan_id || '');
  const [selectedComplaintId, setSelectedComplaintId] = useState<string>(complaints[0]?.complaint_id || '');

  const handleExportCSV = () => {
    const rows = [
      ['Record Type', 'ID', 'Entity/Brand', 'Status/Compliance', 'Created At'],
      ...complaints.map((c) => ['COMPLAINT', c.complaint_id, c.shopkeeper_name || 'Retailer', c.status, c.created_at]),
      ...scans.map((s) => ['FIELD_SCAN', s.scan_id, s.manufacturer_name || 'Manufacturer', s.overall_compliance, s.created_at]),
    ];

    const csvContent = 'data:text/csv;charset=utf-8,' + rows.map((e) => e.join(',')).join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `nirikshak_enforcement_audit_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="tab-wrapper animate-fade-in">
      {/* Top Banner */}
      <div className="reports-hero glass-panel">
        <div className="hero-icon-box">
          <FileCheck2 size={24} className="text-emerald" />
        </div>
        <div className="hero-text">
          <h2 className="hero-title">Official Statutory Report & Notice Generation Center</h2>
          <p className="hero-desc">
            Direct generation of cryptographically fingerprinted (SHA-256) compliance inspection reports, Rule 18(2) overcharging notices, and evidence-backed compound dossiers for court proceedings.
          </p>
        </div>
        <button onClick={handleExportCSV} className="btn-secondary csv-btn">
          <Download size={15} />
          Export Audit Ledger (.CSV)
        </button>
      </div>

      <div className="cards-grid">
        {/* Card 1: Product Scan Compliance PDF Generator */}
        <div className="generator-card glass-panel">
          <div className="gen-card-header">
            <Scale size={20} className="text-emerald" />
            <h3>Statutory Packaging Inspection Report</h3>
          </div>
          <p className="gen-card-desc">
            Complete digital report containing front/back evidence photos, OCR text extracts, font height verification, and legal citations under LMPC Rules 2011.
          </p>

          <div className="selector-box">
            <label className="selector-label">Select Audited Field Scan:</label>
            <select
              value={selectedScanId}
              onChange={(e) => setSelectedScanId(e.target.value)}
              className="gen-select"
            >
              {scans.map((s) => (
                <option key={s.scan_id} value={s.scan_id}>
                  {s.product_name || s.scan_id} ({s.overall_compliance}) - {new Date(s.created_at).toLocaleDateString()}
                </option>
              ))}
            </select>
          </div>

          <div className="statutory-preview-box">
            <div className="cert-row">
              <Fingerprint size={16} className="text-emerald" />
              <span className="cert-text font-mono">Digital Signature & Hash: SHA-256 Auto-Stamped</span>
            </div>
            <div className="cert-row">
              <ShieldCheck size={16} className="text-emerald" />
              <span className="cert-text">Certified Officer: Officer Raj (Badge #LMC-2026-IND)</span>
            </div>
          </div>

          <a
            href={OfficerApi.getScanReportUrl(selectedScanId)}
            target="_blank"
            rel="noreferrer"
            className="btn-primary full-btn"
          >
            <Download size={15} />
            Generate Inspection PDF Report
          </a>
        </div>

        {/* Card 2: Citizen Overcharge Grievance Notice PDF */}
        <div className="generator-card glass-panel">
          <div className="gen-card-header">
            <AlertTriangle size={20} className="text-crimson" />
            <h3>Rule 18(2) Overcharge Statutory Notice</h3>
          </div>
          <p className="gen-card-desc">
            Formal legal notice documenting retail cash memo, printed MRP discrepancy, retailer coordinates, and penalty liability under Section 36 of the Legal Metrology Act.
          </p>

          <div className="selector-box">
            <label className="selector-label">Select Citizen Complaint:</label>
            <select
              value={selectedComplaintId}
              onChange={(e) => setSelectedComplaintId(e.target.value)}
              className="gen-select"
            >
              {complaints.map((c) => (
                <option key={c.complaint_id} value={c.complaint_id}>
                  #{c.complaint_id} - {c.shopkeeper_name || 'Vendor'} (₹{c.paid_price} vs ₹{c.printed_mrp})
                </option>
              ))}
            </select>
          </div>

          <div className="statutory-preview-box">
            <div className="cert-row">
              <Fingerprint size={16} className="text-crimson" />
              <span className="cert-text font-mono">Statutory Notice Stamp: Compounding Form-VII</span>
            </div>
            <div className="cert-row">
              <ShieldCheck size={16} className="text-emerald" />
              <span className="cert-text">Redressal Authority: State Controller of Legal Metrology</span>
            </div>
          </div>

          <a
            href={OfficerApi.getComplaintReportUrl(selectedComplaintId)}
            target="_blank"
            rel="noreferrer"
            className="btn-reject full-btn text-center"
          >
            <Download size={15} />
            Generate Overcharge Grievance PDF
          </a>
        </div>
      </div>

      {/* Verification & Legal Validity Standards */}
      <div className="legal-banner glass-panel">
        <div className="legal-head">
          <ShieldCheck size={18} className="text-emerald" />
          <h4>Legal Metrology Enforcement Validity Guarantee</h4>
        </div>
        <p className="legal-body">
          Reports generated by NIRIKSHAK AI comply with Section 65B of the Indian Evidence Act, 1872 regarding electronic admissibility. All evidence crops, timestamp coordinates, and OCR raw tokens are hashed before document rendering to prevent evidentiary tampering during compounding hearings.
        </p>
      </div>

      <style jsx>{`
        .tab-wrapper {
          display: flex;
          flex-direction: column;
          gap: 18px;
        }

        .reports-hero {
          display: flex;
          align-items: center;
          gap: 18px;
          padding: 18px 24px;
          background: #ecfdf5;
          border: 1px solid #a7f3d0;
        }

        .hero-icon-box {
          width: 48px;
          height: 48px;
          border-radius: 12px;
          background: #d1fae5;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .hero-text {
          flex: 1;
        }

        .hero-title {
          font-size: 1.1rem;
          font-weight: 800;
          color: #0f172a;
        }

        .hero-desc {
          font-size: 0.8rem;
          color: #475569;
          margin-top: 3px;
          line-height: 1.4;
        }

        .csv-btn {
          flex-shrink: 0;
        }

        .cards-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 18px;
        }

        @media (max-width: 900px) {
          .cards-grid {
            grid-template-columns: 1fr;
          }
        }

        .generator-card {
          padding: 22px;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .gen-card-header {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .gen-card-header h3 {
          font-size: 1.05rem;
          font-weight: 800;
          color: #0f172a;
        }

        .gen-card-desc {
          font-size: 0.82rem;
          color: #475569;
          line-height: 1.45;
        }

        .selector-box {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .selector-label {
          font-size: 0.72rem;
          font-weight: 700;
          color: #64748b;
          text-transform: uppercase;
        }

        .gen-select {
          background: #ffffff;
          border: 1px solid #cbd5e1;
          border-radius: 10px;
          padding: 10px 14px;
          color: #0f172a;
          font-size: 0.85rem;
          font-family: var(--font-outfit);
          outline: none;
        }

        .gen-select:focus {
          border-color: #10b981;
        }

        .statutory-preview-box {
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 10px;
          padding: 12px 14px;
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .cert-row {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .cert-text {
          font-size: 0.75rem;
          color: #334155;
          font-weight: 600;
        }

        .full-btn {
          width: 100%;
          text-decoration: none;
          padding: 12px;
          font-size: 0.88rem;
          margin-top: auto;
          text-align: center;
        }

        .legal-banner {
          padding: 16px 20px;
          display: flex;
          flex-direction: column;
          gap: 8px;
          background: #f8fafc;
          border: 1px solid #e2e8f0;
        }

        .legal-head {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .legal-head h4 {
          font-size: 0.88rem;
          font-weight: 800;
          color: #0f172a;
        }

        .legal-body {
          font-size: 0.78rem;
          color: #475569;
          line-height: 1.5;
        }

        .text-emerald {
          color: #059669;
        }

        .text-crimson {
          color: #dc2626;
        }
      `}</style>
    </div>
  );
};
