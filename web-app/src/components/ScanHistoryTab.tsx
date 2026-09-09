'use client';

import React, { useState } from 'react';
import { ScanItem } from '../types';
import { OfficerApi } from '../services/api';
import { 
  CheckCircle2, 
  XCircle, 
  RotateCcw, 
  Download, 
  Clock, 
  ShieldAlert, 
  Package, 
  Layers,
  ChevronDown,
  ChevronUp,
  Scale
} from 'lucide-react';

interface ScanHistoryTabProps {
  scans: ScanItem[];
  onRefresh: () => void;
}

export const ScanHistoryTab: React.FC<ScanHistoryTabProps> = ({ scans, onRefresh }) => {
  const [expandedScanId, setExpandedScanId] = useState<string | null>(scans[0]?.scan_id || null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [reviewNotes, setReviewNotes] = useState<{ [id: string]: string }>({});

  const toggleExpand = (scanId: string) => {
    setExpandedScanId(expandedScanId === scanId ? null : scanId);
  };

  const handleDecision = async (
    scanId: string,
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_RESCAN'
  ) => {
    setActionLoading(scanId);
    const notes = reviewNotes[scanId] || `Enforcement officer decision: ${decision}`;
    await OfficerApi.submitScanReview(
      scanId,
      decision,
      '00000000-0000-0000-0000-000000000001',
      notes
    );
    setActionLoading(null);
    onRefresh();
  };

  return (
    <div className="tab-wrapper animate-fade-in">
      {/* Top Banner */}
      <div className="info-banner glass-panel">
        <div className="banner-icon-box">
          <Scale size={22} className="text-emerald" />
        </div>
        <div>
          <h2 className="banner-title">Field Officer Packaging Audit Stream</h2>
          <p className="banner-subtitle">
            Real-time feed of multi-side packaging photographs, AI OCR field extractions, and statutory evaluations conducted by field enforcement personnel.
          </p>
        </div>
      </div>

      {/* Scans Timeline */}
      <div className="scans-list">
        {scans.map((scan) => {
          const isExpanded = expandedScanId === scan.scan_id;
          const isPass = scan.overall_compliance === 'PASS';
          const isFail = scan.overall_compliance === 'FAIL';
          const score = scan.compliance_summary?.compliance_score ?? (isPass ? 100 : 50);
          const isProcessing = actionLoading === scan.scan_id;

          return (
            <div key={scan.scan_id} className="scan-card glass-panel">
              {/* Scan Card Header */}
              <div className="scan-card-header" onClick={() => toggleExpand(scan.scan_id)}>
                <div className="left-meta">
                  <div className={`status-indicator ${isPass ? 'pass' : isFail ? 'fail' : 'review'}`}>
                    {isPass ? <CheckCircle2 size={20} /> : <ShieldAlert size={20} />}
                  </div>
                  <div>
                    <div className="product-title-row">
                      <h3 className="product-name">{scan.product_name || 'Unregistered Product Pack'}</h3>
                      <span className={`badge ${isPass ? 'badge-emerald' : isFail ? 'badge-crimson' : 'badge-amber'}`}>
                        {scan.overall_compliance} ({score}% SCORE)
                      </span>
                      {scan.decision && (
                        <span className="badge badge-cyan">DECISION: {scan.decision}</span>
                      )}
                    </div>
                    <div className="product-sub-row">
                      <span className="mfr-name">{scan.manufacturer_name || 'Manufacturer Not Declared'}</span>
                      <span className="dot">•</span>
                      <span className="time-text font-mono">
                        <Clock size={12} /> {new Date(scan.created_at).toLocaleString()}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="right-actions" onClick={(e) => e.stopPropagation()}>
                  <a
                    href={OfficerApi.getScanReportUrl(scan.scan_id)}
                    target="_blank"
                    rel="noreferrer"
                    className="btn-primary report-btn"
                    title="Generate & Download Full Statutory PDF"
                  >
                    <Download size={14} />
                    Statutory Report
                  </a>
                  <button onClick={() => toggleExpand(scan.scan_id)} className="expand-btn">
                    {isExpanded ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                  </button>
                </div>
              </div>

              {/* Expanded Inspection Dossier */}
              {isExpanded && (
                <div className="expanded-content animate-fade-in">
                  {/* Extracted Declarations Matrix */}
                  <div className="dossier-section">
                    <div className="section-title-row">
                      <Package size={16} className="text-emerald" />
                      <h4 className="section-heading">LMPC Mandatory Declarations (Extracted vs Ground Truth)</h4>
                    </div>

                    <div className="declarations-grid">
                      {scan.extracted_declarations ? (
                        Object.entries(scan.extracted_declarations).map(([key, val]) => (
                          <div key={key} className="decl-item">
                            <span className="decl-key">{key.replace(/_/g, ' ')}</span>
                            <span className="decl-val font-mono">{String(val || 'Not Detected')}</span>
                          </div>
                        ))
                      ) : (
                        <p className="empty-text">No declarations parsed.</p>
                      )}
                    </div>
                  </div>

                  {/* Rule-by-Rule Evaluations & Violations */}
                  {scan.evaluations && scan.evaluations.length > 0 && (
                    <div className="dossier-section">
                      <div className="section-title-row">
                        <Layers size={16} className="text-emerald" />
                        <h4 className="section-heading">Statutory Rule Evaluations & Citations</h4>
                      </div>

                      <div className="eval-list">
                        {scan.evaluations.map((ev, idx) => (
                          <div
                            key={idx}
                            className={`eval-item ${ev.status === 'FAIL' ? 'fail-border' : 'pass-border'}`}
                          >
                            <div className="eval-top">
                              <span className="eval-title">{ev.rule_title}</span>
                              <span
                                className={`badge ${
                                  ev.status === 'PASS'
                                    ? 'badge-emerald'
                                    : ev.status === 'FAIL'
                                    ? 'badge-crimson'
                                    : 'badge-amber'
                                }`}
                              >
                                {ev.status}
                              </span>
                            </div>
                            <p className="eval-reason">{ev.reason}</p>
                            {ev.citation && (
                              <div className="eval-citation font-mono">
                                <span className="citation-act">[{ev.citation.act_name || 'LMPC Rules 2011'} - {ev.citation.rule_reference}]</span>
                                {ev.citation.quote && <p className="citation-quote">&quot;{ev.citation.quote}&quot;</p>}
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Officer Action Bar */}
                  <div className="officer-decision-bar">
                    <div className="decision-prompt">
                      <span className="prompt-title">Officer Enforcement Action</span>
                      <p className="prompt-desc">
                        Record legal decision into immutable audit trail under Section 15 of Legal Metrology Act, 2009.
                      </p>
                    </div>

                    <div className="decision-input-row">
                      <input
                        type="text"
                        placeholder="Resolution notes / Compound notice reference..."
                        value={reviewNotes[scan.scan_id] || ''}
                        onChange={(e) =>
                          setReviewNotes({
                            ...reviewNotes,
                            [scan.scan_id]: e.target.value,
                          })
                        }
                        className="decision-notes-input"
                      />

                      <div className="btn-group">
                        <button
                          disabled={isProcessing}
                          onClick={() => handleDecision(scan.scan_id, 'ACCEPT')}
                          className="btn-primary"
                        >
                          <CheckCircle2 size={15} />
                          Accept Scan
                        </button>
                        <button
                          disabled={isProcessing}
                          onClick={() => handleDecision(scan.scan_id, 'REJECT')}
                          className="btn-reject"
                        >
                          <XCircle size={15} />
                          Reject Findings
                        </button>
                        <button
                          disabled={isProcessing}
                          onClick={() => handleDecision(scan.scan_id, 'REQUEST_RESCAN')}
                          className="btn-secondary"
                        >
                          <RotateCcw size={15} />
                          Request Rescan
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      <style jsx>{`
        .tab-wrapper {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .info-banner {
          display: flex;
          align-items: center;
          gap: 16px;
          padding: 16px 20px;
          background: #ecfdf5;
          border: 1px solid #a7f3d0;
        }

        .banner-icon-box {
          width: 42px;
          height: 42px;
          border-radius: 12px;
          background: #d1fae5;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .text-emerald {
          color: #059669;
        }

        .banner-title {
          font-size: 1.05rem;
          font-weight: 800;
          color: #0f172a;
        }

        .banner-subtitle {
          font-size: 0.8rem;
          color: #475569;
          margin-top: 2px;
        }

        .scans-list {
          display: flex;
          flex-direction: column;
          gap: 14px;
        }

        .scan-card {
          padding: 16px 20px;
          display: flex;
          flex-direction: column;
        }

        .scan-card-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          cursor: pointer;
        }

        .left-meta {
          display: flex;
          align-items: center;
          gap: 14px;
        }

        .status-indicator {
          width: 38px;
          height: 38px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .status-indicator.pass {
          background: #d1fae5;
          color: #059669;
          border: 1px solid #a7f3d0;
        }

        .status-indicator.fail {
          background: #fee2e2;
          color: #dc2626;
          border: 1px solid #fecaca;
        }

        .status-indicator.review {
          background: #fef3c7;
          color: #d97706;
          border: 1px solid #fde68a;
        }

        .product-title-row {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .product-name {
          font-size: 1rem;
          font-weight: 800;
          color: #0f172a;
        }

        .product-sub-row {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 0.75rem;
          color: #64748b;
          margin-top: 3px;
        }

        .mfr-name {
          color: #334155;
          font-weight: 600;
        }

        .dot {
          color: #cbd5e1;
        }

        .time-text {
          display: flex;
          align-items: center;
          gap: 4px;
        }

        .right-actions {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .report-btn {
          text-decoration: none;
          font-size: 0.8rem;
          padding: 8px 14px;
        }

        .expand-btn {
          background: rgba(255, 255, 255, 0.85);
          border: 1px solid #e2e8f0;
          color: #475569;
          width: 34px;
          height: 34px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        }

        .expanded-content {
          margin-top: 18px;
          border-top: 1px solid #f1f5f9;
          padding-top: 16px;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .dossier-section {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .section-title-row {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .section-heading {
          font-size: 0.85rem;
          font-weight: 800;
          color: #0f172a;
        }

        .declarations-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
          gap: 10px;
          background: rgba(255, 255, 255, 0.9);
          padding: 14px;
          border-radius: 12px;
          border: 1px solid #e2e8f0;
        }

        .decl-item {
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .decl-key {
          font-size: 0.68rem;
          font-weight: 700;
          color: #64748b;
          text-transform: uppercase;
        }

        .decl-val {
          font-size: 0.82rem;
          color: #0f172a;
          word-break: break-word;
          font-weight: 600;
        }

        .eval-list {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .eval-item {
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #e2e8f0;
          padding: 12px 14px;
          border-radius: 10px;
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .eval-item.fail-border {
          border-left: 4px solid #ef4444;
        }

        .eval-item.pass-border {
          border-left: 4px solid #10b981;
        }

        .eval-top {
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .eval-title {
          font-size: 0.85rem;
          font-weight: 700;
          color: #0f172a;
        }

        .eval-reason {
          font-size: 0.8rem;
          color: #475569;
          line-height: 1.4;
        }

        .eval-citation {
          font-size: 0.72rem;
          color: #065f46;
          background: #ecfdf5;
          padding: 6px 10px;
          border-radius: 6px;
          border-left: 2px solid #10b981;
        }

        .citation-act {
          font-weight: 700;
        }

        .citation-quote {
          margin-top: 2px;
          color: #334155;
          font-style: italic;
        }

        .officer-decision-bar {
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          padding: 14px 18px;
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .prompt-title {
          font-size: 0.85rem;
          font-weight: 800;
          color: #0f172a;
        }

        .prompt-desc {
          font-size: 0.75rem;
          color: #64748b;
        }

        .decision-input-row {
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
        }

        .decision-notes-input {
          flex: 1;
          min-width: 250px;
          background: #ffffff;
          border: 1px solid #cbd5e1;
          border-radius: 8px;
          padding: 8px 12px;
          color: #0f172a;
          font-size: 0.8rem;
          font-family: var(--font-outfit);
          outline: none;
        }

        .decision-notes-input:focus {
          border-color: #10b981;
        }

        .btn-group {
          display: flex;
          gap: 8px;
        }
      `}</style>
    </div>
  );
};
