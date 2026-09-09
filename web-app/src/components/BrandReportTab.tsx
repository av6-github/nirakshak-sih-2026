'use client';

import React, { useState } from 'react';
import { BrandRating, BrandDetail } from '../types';
import { OfficerApi } from '../services/api';
import { 
  Building2, 
  Search, 
  ShieldCheck, 
  Edit3, 
  History,
  X
} from 'lucide-react';

interface BrandReportTabProps {
  brands: BrandRating[];
  onRefresh: () => void;
}

export const BrandReportTab: React.FC<BrandReportTabProps> = ({ brands, onRefresh }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBrand, setSelectedBrand] = useState<BrandDetail | null>(null);
  const [ratingModalBrand, setRatingModalBrand] = useState<string | null>(null);
  const [newRating, setNewRating] = useState<'GREEN' | 'YELLOW' | 'RED'>('GREEN');
  const [ratingNotes, setRatingNotes] = useState('');
  const [submittingRating, setSubmittingRating] = useState(false);

  const filteredBrands = brands.filter((b) =>
    b.manufacturer_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleOpenBrandHistory = async (name: string) => {
    const detail = await OfficerApi.getBrandHistory(name);
    setSelectedBrand(detail);
  };

  const handleRateBrand = async () => {
    if (!ratingModalBrand) return;
    setSubmittingRating(true);
    await OfficerApi.rateBrand(ratingModalBrand, newRating, ratingNotes);
    setSubmittingRating(false);
    setRatingModalBrand(null);
    setRatingNotes('');
    onRefresh();
  };

  const getRatingBadge = (rating?: 'RED' | 'YELLOW' | 'GREEN' | null) => {
    switch (rating) {
      case 'GREEN':
        return <span className="badge badge-emerald">GREEN (COMPLIANT)</span>;
      case 'YELLOW':
        return <span className="badge badge-amber">YELLOW (WATCHLIST)</span>;
      case 'RED':
        return <span className="badge badge-crimson">RED (HIGH RISK)</span>;
      default:
        return <span className="badge badge-slate">UNRATED</span>;
    }
  };

  return (
    <div className="tab-wrapper animate-fade-in">
      {/* Top Search & Matrix Overview */}
      <div className="top-search-row glass-panel">
        <div className="search-bar">
          <Search size={18} className="search-icon" />
          <input
            type="text"
            placeholder="Search brand, manufacturer, or corporate entity (e.g. Amul, Haldiram, Nestle)..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="brand-search-input"
          />
          {searchQuery && (
            <button onClick={() => setSearchQuery('')} className="clear-btn">
              <X size={14} />
            </button>
          )}
        </div>

        <div className="quick-stats-row">
          <div className="stat-pill">
            <span className="stat-num">{brands.length}</span>
            <span className="stat-label">Monitored Brands</span>
          </div>
          <div className="stat-pill">
            <span className="stat-num text-emerald">
              {brands.filter((b) => b.officer_rating === 'GREEN').length}
            </span>
            <span className="stat-label">Green Tier</span>
          </div>
          <div className="stat-pill">
            <span className="stat-num text-crimson">
              {brands.filter((b) => b.officer_rating === 'RED').length}
            </span>
            <span className="stat-label">Red Tier</span>
          </div>
        </div>
      </div>

      {/* Brand Cards Grid */}
      <div className="brands-grid">
        {filteredBrands.map((brand) => {
          const failCount = brand.total_scans - brand.passed_scans;
          const score = brand.ai_compliance_score;

          return (
            <div key={brand.manufacturer_name} className="brand-card glass-panel">
              <div className="brand-card-top">
                <div className="brand-icon-box">
                  <Building2 size={20} className="text-emerald" />
                </div>
                <div className="brand-title-box">
                  <h3 className="brand-title">{brand.manufacturer_name}</h3>
                  <div className="rating-row">
                    {getRatingBadge(brand.officer_rating)}
                  </div>
                </div>
              </div>

              {/* Compliance Score Bar */}
              <div className="score-section">
                <div className="score-row">
                  <span className="score-label">Statutory Compliance Score</span>
                  <span className="score-val font-mono">{score.toFixed(1)}%</span>
                </div>
                <div className="progress-track">
                  <div
                    className="progress-fill"
                    style={{
                      width: `${score}%`,
                      backgroundColor: score >= 85 ? '#10b981' : score >= 60 ? '#f59e0b' : '#ef4444',
                    }}
                  ></div>
                </div>
              </div>

              {/* Audit Counts */}
              <div className="audit-metrics">
                <div className="metric-box">
                  <span className="m-val font-mono">{brand.total_scans}</span>
                  <span className="m-lbl">Total Scans</span>
                </div>
                <div className="metric-box">
                  <span className="m-val text-emerald font-mono">{brand.passed_scans}</span>
                  <span className="m-lbl">Passed</span>
                </div>
                <div className="metric-box">
                  <span className="m-val text-crimson font-mono">{failCount}</span>
                  <span className="m-lbl">Violations</span>
                </div>
              </div>

              {/* Officer Notes if any */}
              {brand.officer_notes && (
                <div className="officer-notes-box">
                  <span className="notes-heading">Officer Audit Remark:</span>
                  <p className="notes-content">{brand.officer_notes}</p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="brand-card-footer">
                <button
                  onClick={() => handleOpenBrandHistory(brand.manufacturer_name)}
                  className="btn-secondary brand-action-btn"
                >
                  <History size={14} />
                  Inspection History
                </button>
                <button
                  onClick={() => {
                    setRatingModalBrand(brand.manufacturer_name);
                    setNewRating(brand.officer_rating || 'GREEN');
                    setRatingNotes(brand.officer_notes || '');
                  }}
                  className="btn-primary brand-action-btn"
                >
                  <Edit3 size={14} />
                  Assign Rating
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Brand History Modal */}
      {selectedBrand && (
        <div className="modal-backdrop" onClick={() => setSelectedBrand(null)}>
          <div className="modal-card glass-panel" onClick={(e) => e.stopPropagation()}>
            <div className="modal-head">
              <div className="modal-title-row">
                <Building2 size={20} className="text-emerald" />
                <h3>{selectedBrand.manufacturer_name} - Inspection Dossier</h3>
              </div>
              <button onClick={() => setSelectedBrand(null)} className="close-btn">
                <X size={18} />
              </button>
            </div>

            <div className="modal-body">
              <div className="summary-banner">
                <div>
                  <span className="sum-lbl">Total Audited Inspections:</span>
                  <span className="sum-val font-mono">{selectedBrand.total_scans}</span>
                </div>
                <div>
                  <span className="sum-lbl">Overall Score:</span>
                  <span className="sum-val text-emerald font-mono">{selectedBrand.compliance_score}%</span>
                </div>
              </div>

              <div className="history-table-wrapper">
                <table className="history-table">
                  <thead>
                    <tr>
                      <th>Date</th>
                      <th>Product Audited</th>
                      <th>Compliance Result</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedBrand.history.map((h, i) => (
                      <tr key={i}>
                        <td className="font-mono">{new Date(h.date).toLocaleDateString()}</td>
                        <td>{h.product_name || 'Commodity Package'}</td>
                        <td>
                          <span
                            className={`badge ${
                              h.status === 'PASS' ? 'badge-emerald' : 'badge-crimson'
                            }`}
                          >
                            {h.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Rate Brand Modal */}
      {ratingModalBrand && (
        <div className="modal-backdrop" onClick={() => setRatingModalBrand(null)}>
          <div className="rating-modal glass-panel" onClick={(e) => e.stopPropagation()}>
            <div className="modal-head">
              <div className="modal-title-row">
                <ShieldCheck size={20} className="text-emerald" />
                <h3>Assign Officer Trust Rating: {ratingModalBrand}</h3>
              </div>
              <button onClick={() => setRatingModalBrand(null)} className="close-btn">
                <X size={18} />
              </button>
            </div>

            <div className="rating-body">
              <p className="rating-desc">
                Enforcement officer rating assigns statutory compliance priority. This updates the public trust portal and risk assessment engine.
              </p>

              <div className="rating-options">
                {(['GREEN', 'YELLOW', 'RED'] as const).map((r) => (
                  <button
                    key={r}
                    onClick={() => setNewRating(r)}
                    className={`tier-btn ${r.toLowerCase()} ${newRating === r ? 'active' : ''}`}
                  >
                    {r === 'GREEN' && 'GREEN (Compliant)'}
                    {r === 'YELLOW' && 'YELLOW (Under Watch)'}
                    {r === 'RED' && 'RED (High Risk Offender)'}
                  </button>
                ))}
              </div>

              <div className="notes-input-group">
                <label className="input-lbl">Officer Statutory Notes & Basis:</label>
                <textarea
                  rows={3}
                  placeholder="Enter reason for rating, past inspection notices, or compounding details..."
                  value={ratingNotes}
                  onChange={(e) => setRatingNotes(e.target.value)}
                  className="notes-textarea"
                ></textarea>
              </div>

              <div className="modal-actions">
                <button
                  onClick={() => setRatingModalBrand(null)}
                  className="btn-secondary"
                >
                  Cancel
                </button>
                <button
                  disabled={submittingRating}
                  onClick={handleRateBrand}
                  className="btn-primary"
                >
                  Save Officer Rating
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <style jsx>{`
        .tab-wrapper {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .top-search-row {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 14px 20px;
          gap: 16px;
          flex-wrap: wrap;
        }

        .search-bar {
          display: flex;
          align-items: center;
          gap: 10px;
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          padding: 8px 14px;
          flex: 1;
          min-width: 300px;
          box-shadow: 0 1px 4px rgba(0, 0, 0, 0.02);
        }

        .search-icon {
          color: #94a3b8;
        }

        .brand-search-input {
          background: transparent;
          border: none;
          outline: none;
          color: #0f172a;
          font-size: 0.88rem;
          font-family: var(--font-outfit);
          width: 100%;
        }

        .brand-search-input::placeholder {
          color: #94a3b8;
        }

        .clear-btn {
          background: transparent;
          border: none;
          color: #94a3b8;
          cursor: pointer;
        }

        .quick-stats-row {
          display: flex;
          gap: 10px;
        }

        .stat-pill {
          display: flex;
          align-items: center;
          gap: 8px;
          background: rgba(255, 255, 255, 0.85);
          border: 1px solid #e2e8f0;
          padding: 6px 14px;
          border-radius: 10px;
        }

        .stat-num {
          font-size: 0.95rem;
          font-weight: 800;
          font-family: var(--font-mono);
          color: #0f172a;
        }

        .stat-label {
          font-size: 0.72rem;
          color: #64748b;
          font-weight: 600;
        }

        .text-emerald {
          color: #059669;
        }

        .text-crimson {
          color: #dc2626;
        }

        .brands-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
          gap: 16px;
        }

        .brand-card {
          padding: 18px;
          display: flex;
          flex-direction: column;
          gap: 14px;
        }

        .brand-card-top {
          display: flex;
          align-items: flex-start;
          gap: 12px;
        }

        .brand-icon-box {
          width: 40px;
          height: 40px;
          border-radius: 12px;
          background: #d1fae5;
          border: 1px solid #a7f3d0;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .brand-title-box {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }

        .brand-title {
          font-size: 0.95rem;
          font-weight: 800;
          color: #0f172a;
          line-height: 1.3;
        }

        .rating-row {
          display: flex;
        }

        .score-section {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .score-row {
          display: flex;
          justify-content: space-between;
          font-size: 0.75rem;
        }

        .score-label {
          color: #64748b;
          font-weight: 600;
        }

        .score-val {
          font-weight: 800;
          color: #0f172a;
        }

        .progress-track {
          width: 100%;
          height: 6px;
          background: #e2e8f0;
          border-radius: 9999px;
          overflow: hidden;
        }

        .progress-fill {
          height: 100%;
          border-radius: 9999px;
          transition: width 0.4s ease;
        }

        .audit-metrics {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 8px;
          background: rgba(255, 255, 255, 0.9);
          padding: 10px;
          border-radius: 10px;
          border: 1px solid #e2e8f0;
          text-align: center;
        }

        .metric-box {
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .m-val {
          font-size: 1rem;
          font-weight: 800;
          color: #0f172a;
        }

        .m-lbl {
          font-size: 0.68rem;
          color: #64748b;
          text-transform: uppercase;
          font-weight: 700;
        }

        .officer-notes-box {
          background: #f8fafc;
          border-left: 3px solid #10b981;
          padding: 8px 10px;
          border-radius: 4px;
        }

        .notes-heading {
          font-size: 0.68rem;
          font-weight: 800;
          color: #065f46;
          text-transform: uppercase;
        }

        .notes-content {
          font-size: 0.78rem;
          color: #475569;
          margin-top: 2px;
        }

        .brand-card-footer {
          display: flex;
          gap: 8px;
          margin-top: auto;
          padding-top: 6px;
        }

        .brand-action-btn {
          flex: 1;
          font-size: 0.78rem;
          padding: 7px 10px;
        }

        /* Modals */
        .modal-backdrop {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(15, 23, 42, 0.45);
          backdrop-filter: blur(8px);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 100;
          padding: 20px;
        }

        .modal-card {
          width: 100%;
          max-width: 650px;
          background: #ffffff;
          border-radius: 16px;
          border: 1px solid rgba(255, 255, 255, 0.9);
          box-shadow: 0 20px 50px rgba(15, 23, 42, 0.15);
          overflow: hidden;
        }

        .rating-modal {
          width: 100%;
          max-width: 520px;
          background: #ffffff;
          border-radius: 16px;
          border: 1px solid rgba(255, 255, 255, 0.9);
          box-shadow: 0 20px 50px rgba(15, 23, 42, 0.15);
          overflow: hidden;
        }

        .modal-head {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 16px 20px;
          border-bottom: 1px solid #e2e8f0;
        }

        .modal-title-row {
          display: flex;
          align-items: center;
          gap: 10px;
          font-size: 1rem;
          font-weight: 800;
          color: #0f172a;
        }

        .close-btn {
          background: transparent;
          border: none;
          color: #64748b;
          cursor: pointer;
        }

        .modal-body {
          padding: 20px;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .summary-banner {
          display: flex;
          gap: 24px;
          background: #f8fafc;
          padding: 12px 16px;
          border-radius: 10px;
          border: 1px solid #e2e8f0;
        }

        .sum-lbl {
          font-size: 0.72rem;
          color: #64748b;
          display: block;
          font-weight: 600;
        }

        .sum-val {
          font-size: 1.1rem;
          font-weight: 800;
          color: #0f172a;
        }

        .history-table-wrapper {
          overflow-x: auto;
        }

        .history-table {
          width: 100%;
          border-collapse: collapse;
          font-size: 0.8rem;
        }

        .history-table th {
          text-align: left;
          padding: 8px 12px;
          color: #64748b;
          font-weight: 700;
          border-bottom: 1px solid #e2e8f0;
        }

        .history-table td {
          padding: 10px 12px;
          border-bottom: 1px solid #f1f5f9;
          color: #334155;
          font-weight: 500;
        }

        .rating-body {
          padding: 20px;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .rating-desc {
          font-size: 0.8rem;
          color: #475569;
          line-height: 1.4;
        }

        .rating-options {
          display: flex;
          gap: 8px;
        }

        .tier-btn {
          flex: 1;
          padding: 10px;
          border-radius: 10px;
          font-size: 0.75rem;
          font-weight: 700;
          font-family: var(--font-outfit);
          cursor: pointer;
          border: 1px solid #e2e8f0;
          background: #f8fafc;
          color: #475569;
          transition: all 0.2s;
        }

        .tier-btn.green.active {
          background: #d1fae5;
          border-color: #10b981;
          color: #065f46;
        }

        .tier-btn.yellow.active {
          background: #fef3c7;
          border-color: #f59e0b;
          color: #92400e;
        }

        .tier-btn.red.active {
          background: #fee2e2;
          border-color: #ef4444;
          color: #991b1b;
        }

        .notes-input-group {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .input-lbl {
          font-size: 0.72rem;
          font-weight: 700;
          color: #64748b;
        }

        .notes-textarea {
          background: #ffffff;
          border: 1px solid #cbd5e1;
          border-radius: 8px;
          padding: 10px;
          color: #0f172a;
          font-size: 0.8rem;
          font-family: var(--font-outfit);
          outline: none;
          resize: vertical;
        }

        .modal-actions {
          display: flex;
          justify-content: flex-end;
          gap: 10px;
        }
      `}</style>
    </div>
  );
};
