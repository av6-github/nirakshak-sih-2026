'use client';

import React from 'react';
import { X, ExternalLink, ShieldAlert } from 'lucide-react';

interface EvidenceModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  receiptUrl?: string;
  productUrl?: string;
  description?: string;
  notes?: string;
}

export const EvidenceModal: React.FC<EvidenceModalProps> = ({
  isOpen,
  onClose,
  title,
  receiptUrl,
  productUrl,
  description,
  notes,
}) => {
  if (!isOpen) return null;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content glass-panel" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="title-group">
            <ShieldAlert className="text-emerald" size={20} />
            <h3 className="modal-title">{title}</h3>
          </div>
          <button onClick={onClose} className="close-btn">
            <X size={18} />
          </button>
        </div>

        <div className="modal-body">
          {description && (
            <div className="desc-box">
              <span className="desc-label">Grievance Description / Citizen Statement:</span>
              <p className="desc-text">{description}</p>
            </div>
          )}

          <div className="photos-grid">
            {/* Receipt Photo */}
            <div className="photo-card">
              <div className="photo-header">
                <span>Receipt / Cash Memo Evidence</span>
                {receiptUrl && (
                  <a href={receiptUrl} target="_blank" rel="noreferrer" className="open-link">
                    <ExternalLink size={12} /> Full Size
                  </a>
                )}
              </div>
              <div className="image-frame">
                {receiptUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={receiptUrl} alt="Receipt Evidence" className="evidence-img" />
                ) : (
                  <div className="empty-photo">No Receipt Image Uploaded</div>
                )}
              </div>
            </div>

            {/* Product Photo */}
            <div className="photo-card">
              <div className="photo-header">
                <span>Physical Packaging Photo</span>
                {productUrl && (
                  <a href={productUrl} target="_blank" rel="noreferrer" className="open-link">
                    <ExternalLink size={12} /> Full Size
                  </a>
                )}
              </div>
              <div className="image-frame">
                {productUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={productUrl} alt="Product Packaging Evidence" className="evidence-img" />
                ) : (
                  <div className="empty-photo">No Product Image Uploaded</div>
                )}
              </div>
            </div>
          </div>

          {notes && (
            <div className="notes-box">
              <span className="notes-label">Officer Resolution Notes:</span>
              <p className="notes-text">{notes}</p>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button onClick={onClose} className="btn-secondary">
            Close Evidence Viewer
          </button>
        </div>
      </div>

      <style jsx>{`
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

        .modal-content {
          width: 100%;
          max-width: 720px;
          max-height: 90vh;
          display: flex;
          flex-direction: column;
          background: #ffffff;
          border: 1px solid rgba(255, 255, 255, 0.9);
          border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 25px 50px -12px rgba(15, 23, 42, 0.15);
        }

        .modal-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 16px 20px;
          border-bottom: 1px solid #e2e8f0;
        }

        .title-group {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .text-emerald {
          color: #059669;
        }

        .modal-title {
          font-size: 1.05rem;
          font-weight: 800;
          color: #0f172a;
        }

        .close-btn {
          background: transparent;
          border: none;
          color: #64748b;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          width: 32px;
          height: 32px;
          border-radius: 8px;
          transition: background 0.2s;
        }

        .close-btn:hover {
          background: #f1f5f9;
          color: #0f172a;
        }

        .modal-body {
          padding: 20px;
          overflow-y: auto;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .desc-box {
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 10px;
          padding: 12px 14px;
        }

        .desc-label {
          font-size: 0.72rem;
          font-weight: 700;
          color: #64748b;
          text-transform: uppercase;
        }

        .desc-text {
          font-size: 0.85rem;
          color: #334155;
          margin-top: 4px;
          line-height: 1.5;
        }

        .photos-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
        }

        .photo-card {
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          overflow: hidden;
          display: flex;
          flex-direction: column;
        }

        .photo-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 8px 12px;
          font-size: 0.75rem;
          font-weight: 700;
          color: #334155;
          background: #ffffff;
          border-bottom: 1px solid #e2e8f0;
        }

        .open-link {
          display: flex;
          align-items: center;
          gap: 4px;
          color: #059669;
          text-decoration: none;
          font-size: 0.7rem;
        }

        .image-frame {
          height: 240px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #f1f5f9;
          overflow: hidden;
        }

        .evidence-img {
          width: 100%;
          height: 100%;
          object-fit: contain;
        }

        .empty-photo {
          font-size: 0.75rem;
          color: #94a3b8;
        }

        .notes-box {
          background: #ecfdf5;
          border: 1px solid #a7f3d0;
          border-radius: 10px;
          padding: 12px 14px;
        }

        .notes-label {
          font-size: 0.72rem;
          font-weight: 800;
          color: #065f46;
        }

        .notes-text {
          font-size: 0.85rem;
          color: #047857;
          margin-top: 4px;
        }

        .modal-footer {
          padding: 14px 20px;
          border-top: 1px solid #e2e8f0;
          display: flex;
          justify-content: flex-end;
        }
      `}</style>
    </div>
  );
};
