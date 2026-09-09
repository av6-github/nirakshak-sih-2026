'use client';

import React, { useState } from 'react';
import { Complaint } from '../types';
import { OfficerApi } from '../services/api';
import { 
  CheckCircle2, 
  XCircle, 
  Eye, 
  Download, 
  Filter, 
  Search, 
  Store, 
  MapPin, 
  IndianRupee,
  Clock,
  User,
  ShieldAlert
} from 'lucide-react';

interface ComplaintsTabProps {
  complaints: Complaint[];
  onRefresh: () => void;
  onOpenEvidence: (title: string, receipt?: string, product?: string, desc?: string, notes?: string) => void;
}

export const ComplaintsTab: React.FC<ComplaintsTabProps> = ({
  complaints,
  onRefresh,
  onOpenEvidence,
}) => {
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [resolutionNoteInput, setResolutionNoteInput] = useState<{ [id: string]: string }>({});

  const handleDecision = async (complaintId: string, status: 'RESOLVED' | 'REJECTED') => {
    setActionLoading(complaintId);
    const note = resolutionNoteInput[complaintId] || (status === 'RESOLVED' ? 'Officer Raj validated overcharge violation under LMPC Rule 18(2).' : 'Rejected: Paid amount matches printed packaging declarations.');
    await OfficerApi.reviewComplaint(complaintId, status, 'Officer Raj (ID: LMC-2026-IND)', note);
    setActionLoading(null);
    onRefresh();
  };

  const filtered = complaints.filter((c) => {
    const matchesStatus = filterStatus === 'ALL' || c.status === filterStatus;
    const query = searchQuery.toLowerCase();
    const matchesSearch = 
      !searchQuery ||
      c.citizen_id.toLowerCase().includes(query) ||
      (c.shopkeeper_name && c.shopkeeper_name.toLowerCase().includes(query)) ||
      (c.description && c.description.toLowerCase().includes(query)) ||
      c.complaint_id.toLowerCase().includes(query);
    return matchesStatus && matchesSearch;
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'SUBMITTED':
        return <span className="badge badge-crimson">Pending Review</span>;
      case 'UNDER_REVIEW':
        return <span className="badge badge-amber">Under Audit</span>;
      case 'RESOLVED':
        return <span className="badge badge-emerald">Accepted & Resolved</span>;
      case 'REJECTED':
        return <span className="badge badge-slate">Rejected</span>;
      default:
        return <span className="badge badge-slate">{status}</span>;
    }
  };

  return (
    <div className="tab-wrapper animate-fade-in">
      {/* Top Filter & Search Controls */}
      <div className="controls-bar glass-panel">
        <div className="search-box">
          <Search size={16} className="search-icon" />
          <input
            type="text"
            placeholder="Search citizen (Dev), store, grievance, or complaint ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-input"
          />
        </div>

        <div className="filter-group">
          <Filter size={15} className="filter-icon" />
          <span className="filter-label">Filter:</span>
          {['ALL', 'SUBMITTED', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED'].map((st) => (
            <button
              key={st}
              onClick={() => setFilterStatus(st)}
              className={`filter-btn ${filterStatus === st ? 'active' : ''}`}
            >
              {st === 'ALL' ? 'All Grievances' : st.replace('_', ' ')}
            </button>
          ))}
        </div>
      </div>

      {/* Complaints Feed */}
      <div className="complaints-list">
        {filtered.length === 0 ? (
          <div className="empty-state glass-panel">
            <ShieldAlert size={36} className="empty-icon" />
            <h3>No complaints found</h3>
            <p>No complaints match the current filter or search criteria.</p>
          </div>
        ) : (
          filtered.map((c) => {
            const isOvercharge = c.paid_price > c.printed_mrp;
            const diff = (c.paid_price - c.printed_mrp).toFixed(2);
            const isProcessing = actionLoading === c.complaint_id;

            return (
              <div key={c.complaint_id} className="complaint-card glass-panel">
                {/* Header Row */}
                <div className="card-top">
                  <div className="complaint-id-box">
                    <span className="id-label font-mono">#{c.complaint_id}</span>
                    {getStatusBadge(c.status)}
                    {isOvercharge && (
                      <span className="badge badge-crimson">Rule 18(2) Overcharge</span>
                    )}
                  </div>
                  <div className="time-box font-mono">
                    <Clock size={13} />
                    <span>{new Date(c.created_at).toLocaleString()}</span>
                  </div>
                </div>

                {/* Main Content Grid */}
                <div className="card-grid">
                  {/* Left: Citizen & Store Details */}
                  <div className="grid-col">
                    <div className="detail-row">
                      <User size={15} className="detail-icon" />
                      <div>
                        <span className="detail-label">Complainant:</span>
                        <p className="detail-value citizen-name">{c.citizen_id}</p>
                      </div>
                    </div>

                    <div className="detail-row">
                      <Store size={15} className="detail-icon" />
                      <div>
                        <span className="detail-label">Store / Vendor:</span>
                        <p className="detail-value">{c.shopkeeper_name || 'Retail Vendor'}</p>
                      </div>
                    </div>

                    <div className="detail-row">
                      <MapPin size={15} className="detail-icon" />
                      <div>
                        <span className="detail-label">Location / Address:</span>
                        <p className="detail-value address-value">{c.shop_address || 'Not Provided'}</p>
                      </div>
                    </div>
                  </div>

                  {/* Center: Financial Discrepancy Breakdown */}
                  <div className="grid-col price-box">
                    <span className="detail-label">LMPC Price Audit:</span>
                    <div className="price-comparison">
                      <div className="price-tag paid">
                        <span className="tag-label">Charged Price</span>
                        <span className="tag-value font-mono">₹{c.paid_price.toFixed(2)}</span>
                      </div>
                      <div className="diff-arrow">vs</div>
                      <div className="price-tag mrp">
                        <span className="tag-label">Printed MRP</span>
                        <span className="tag-value font-mono">₹{c.printed_mrp.toFixed(2)}</span>
                      </div>
                    </div>
                    {isOvercharge ? (
                      <div className="overcharge-banner">
                        <IndianRupee size={13} />
                        <span>Overcharge Variance: +₹{diff}</span>
                      </div>
                    ) : (
                      <div className="compliant-banner">
                        <span>Priced at or below MRP</span>
                      </div>
                    )}
                  </div>

                  {/* Right: Evidence & Actions */}
                  <div className="grid-col actions-col">
                    <div className="evidence-buttons">
                      <button
                        onClick={() =>
                          onOpenEvidence(
                            `Evidence: #${c.complaint_id} (${c.shopkeeper_name || 'Store'})`,
                            c.receipt_image_url,
                            c.product_image_url,
                            c.description,
                            c.resolution_notes
                          )
                        }
                        className="btn-secondary evidence-btn"
                      >
                        <Eye size={15} />
                        Evidence Photos
                      </button>

                      <a
                        href={OfficerApi.getComplaintReportUrl(c.complaint_id)}
                        target="_blank"
                        rel="noreferrer"
                        className="btn-secondary report-download-btn"
                        title="Download Statutory Complaint Notice PDF"
                      >
                        <Download size={15} />
                        PDF Notice
                      </a>
                    </div>

                    {/* Quick Resolution Input */}
                    {c.status === 'SUBMITTED' || c.status === 'UNDER_REVIEW' ? (
                      <div className="decision-actions">
                        <input
                          type="text"
                          placeholder="Audit remarks / compound fine note..."
                          value={resolutionNoteInput[c.complaint_id] || ''}
                          onChange={(e) =>
                            setResolutionNoteInput({
                              ...resolutionNoteInput,
                              [c.complaint_id]: e.target.value,
                            })
                          }
                          className="decision-note-input"
                        />
                        <div className="decision-buttons">
                          <button
                            disabled={isProcessing}
                            onClick={() => handleDecision(c.complaint_id, 'RESOLVED')}
                            className="btn-primary"
                          >
                            <CheckCircle2 size={15} />
                            Accept
                          </button>
                          <button
                            disabled={isProcessing}
                            onClick={() => handleDecision(c.complaint_id, 'REJECTED')}
                            className="btn-reject"
                          >
                            <XCircle size={15} />
                            Reject
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="audit-logged-banner">
                        <CheckCircle2 size={14} className="text-emerald" />
                        <span>Enforcement decision logged by Officer Raj</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Citizen statement snippet */}
                {c.description && (
                  <div className="card-desc">
                    <span className="desc-heading">Citizen grievance note: </span>
                    <span>{c.description}</span>
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>

      <style jsx>{`
        .tab-wrapper {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .controls-bar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 12px 18px;
          gap: 16px;
          flex-wrap: wrap;
        }

        .search-box {
          display: flex;
          align-items: center;
          gap: 10px;
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          padding: 8px 14px;
          flex: 1;
          min-width: 280px;
          box-shadow: 0 1px 4px rgba(0, 0, 0, 0.02);
        }

        .search-icon {
          color: #94a3b8;
        }

        .search-input {
          background: transparent;
          border: none;
          outline: none;
          color: #0f172a;
          font-size: 0.85rem;
          font-family: var(--font-outfit);
          width: 100%;
        }

        .search-input::placeholder {
          color: #94a3b8;
        }

        .filter-group {
          display: flex;
          align-items: center;
          gap: 8px;
          flex-wrap: wrap;
        }

        .filter-icon {
          color: #64748b;
        }

        .filter-label {
          font-size: 0.75rem;
          color: #64748b;
          font-weight: 700;
        }

        .filter-btn {
          background: rgba(255, 255, 255, 0.85);
          border: 1px solid #e2e8f0;
          color: #475569;
          padding: 5px 12px;
          border-radius: 8px;
          font-size: 0.75rem;
          font-weight: 700;
          font-family: var(--font-outfit);
          cursor: pointer;
          transition: all 0.2s;
        }

        .filter-btn:hover {
          background: #ffffff;
          color: #0f172a;
          border-color: #cbd5e1;
        }

        .filter-btn.active {
          background: #0f172a;
          border-color: #0f172a;
          color: #ffffff;
          box-shadow: 0 2px 8px rgba(15, 23, 42, 0.15);
        }

        .complaints-list {
          display: flex;
          flex-direction: column;
          gap: 14px;
        }

        .empty-state {
          padding: 48px;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 12px;
          text-align: center;
          color: #64748b;
        }

        .empty-icon {
          color: #94a3b8;
        }

        .complaint-card {
          padding: 18px 20px;
          display: flex;
          flex-direction: column;
          gap: 14px;
        }

        .card-top {
          display: flex;
          align-items: center;
          justify-content: space-between;
          border-bottom: 1px solid #f1f5f9;
          padding-bottom: 10px;
        }

        .complaint-id-box {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .id-label {
          font-size: 0.85rem;
          font-weight: 700;
          color: #0f172a;
        }

        .time-box {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 0.72rem;
          color: #64748b;
        }

        .card-grid {
          display: grid;
          grid-template-columns: 1.2fr 1fr 1.3fr;
          gap: 18px;
        }

        @media (max-width: 1024px) {
          .card-grid {
            grid-template-columns: 1fr;
          }
        }

        .grid-col {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .detail-row {
          display: flex;
          align-items: flex-start;
          gap: 10px;
        }

        .detail-icon {
          color: #64748b;
          margin-top: 3px;
        }

        .detail-label {
          font-size: 0.68rem;
          font-weight: 700;
          color: #64748b;
          text-transform: uppercase;
          letter-spacing: 0.03em;
        }

        .detail-value {
          font-size: 0.85rem;
          color: #0f172a;
          font-weight: 600;
          margin-top: 1px;
        }

        .citizen-name {
          color: #047857;
        }

        .address-value {
          color: #475569;
          font-size: 0.8rem;
        }

        .price-box {
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          padding: 12px;
          justify-content: center;
          box-shadow: 0 2px 6px rgba(15, 23, 42, 0.02);
        }

        .price-comparison {
          display: flex;
          align-items: center;
          justify-content: space-around;
          margin-top: 6px;
        }

        .price-tag {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 2px;
        }

        .tag-label {
          font-size: 0.68rem;
          color: #64748b;
          font-weight: 600;
        }

        .tag-value {
          font-size: 1.15rem;
          font-weight: 800;
        }

        .price-tag.paid .tag-value {
          color: #dc2626;
        }

        .price-tag.mrp .tag-value {
          color: #059669;
        }

        .diff-arrow {
          font-size: 0.75rem;
          font-weight: 700;
          color: #94a3b8;
        }

        .overcharge-banner {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          background: #fee2e2;
          border: 1px solid #fecaca;
          color: #991b1b;
          padding: 6px;
          border-radius: 8px;
          font-size: 0.78rem;
          font-weight: 700;
          margin-top: 8px;
        }

        .compliant-banner {
          text-align: center;
          background: #d1fae5;
          color: #065f46;
          padding: 6px;
          border-radius: 8px;
          font-size: 0.75rem;
          font-weight: 700;
          margin-top: 8px;
        }

        .actions-col {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .evidence-buttons {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .evidence-btn {
          flex: 1;
        }

        .report-download-btn {
          text-decoration: none;
        }

        .decision-actions {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .decision-note-input {
          background: rgba(255, 255, 255, 0.95);
          border: 1px solid #cbd5e1;
          border-radius: 8px;
          padding: 8px 12px;
          color: #0f172a;
          font-size: 0.78rem;
          font-family: var(--font-outfit);
          outline: none;
        }

        .decision-note-input:focus {
          border-color: #10b981;
          box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
        }

        .decision-buttons {
          display: flex;
          gap: 8px;
        }

        .decision-buttons button {
          flex: 1;
        }

        .audit-logged-banner {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 10px 14px;
          background: #d1fae5;
          border: 1px solid #a7f3d0;
          border-radius: 8px;
          font-size: 0.8rem;
          font-weight: 700;
          color: #065f46;
        }

        .card-desc {
          background: rgba(241, 245, 249, 0.7);
          border: 1px solid #e2e8f0;
          padding: 8px 12px;
          border-radius: 8px;
          font-size: 0.8rem;
          color: #475569;
          line-height: 1.4;
        }

        .desc-heading {
          font-weight: 700;
          color: #0f172a;
        }

        .text-emerald {
          color: #059669;
        }
      `}</style>
    </div>
  );
};
