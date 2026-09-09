'use client';

import React from 'react';
import Image from 'next/image';
import { ShieldCheck, RefreshCw } from 'lucide-react';

interface HeaderProps {
  onRefresh?: () => void;
  activeTabTitle: string;
}

export const Header: React.FC<HeaderProps> = ({ onRefresh, activeTabTitle }) => {
  return (
    <header className="header-container">
      {/* Brand & Emblem (Matching NirikshakAppBar.dart) */}
      <div className="brand-section">
        <div className="logo-wrapper">
          <Image
            src="/nirikshak_logo.jpeg"
            alt="Nirikshak AI Logo"
            width={40}
            height={40}
            className="logo-img"
            priority
          />
        </div>
        <div className="brand-text-col">
          <div className="title-row">
            <h1 className="brand-title">निरीक्षक AI</h1>
            <span className="badge-lmpc">LMPC 2011</span>
            <span className="badge badge-cyan">OFFICER COMMAND</span>
          </div>
          <p className="brand-subtitle">
            Legal Metrology Packaging Surveillance & Enforcement Portal
          </p>
        </div>
      </div>

      {/* Officer Credentials & Status */}
      <div className="officer-section">
        <div className="live-status-pill">
          <span className="live-pulse"></span>
          <span className="live-text">Surveillance Grid Online</span>
        </div>

        {onRefresh && (
          <button onClick={onRefresh} className="icon-button" title="Refresh Live Data">
            <RefreshCw size={15} />
          </button>
        )}

        <div className="officer-card">
          <div className="officer-avatar">
            <span>RAJ</span>
          </div>
          <div className="officer-info">
            <div className="officer-name-row">
              <ShieldCheck size={14} className="text-emerald" />
              <span className="officer-name">Officer Raj</span>
            </div>
            <span className="officer-id">Badge #LMC-2026-IND</span>
          </div>
        </div>
      </div>

      <style jsx>{`
        .header-container {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 12px 28px;
          background: rgba(255, 255, 255, 0.82);
          backdrop-filter: blur(20px);
          -webkit-backdrop-filter: blur(20px);
          border-bottom: 1px solid rgba(255, 255, 255, 0.9);
          box-shadow: 0 4px 20px rgba(15, 23, 42, 0.04);
          position: sticky;
          top: 0;
          z-index: 50;
        }

        .brand-section {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .logo-wrapper {
          width: 42px;
          height: 42px;
          border-radius: 12px;
          overflow: hidden;
          background: #0f172a;
          border: 1.5px solid rgba(255, 255, 255, 0.9);
          box-shadow: 0 2px 8px rgba(15, 23, 42, 0.1);
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .logo-img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .brand-text-col {
          display: flex;
          flex-direction: column;
        }

        .title-row {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .brand-title {
          font-size: 1.25rem;
          font-weight: 800;
          color: #0f172a;
          letter-spacing: -0.02em;
          font-family: var(--font-outfit);
        }

        .badge-lmpc {
          padding: 2px 7px;
          border-radius: 20px;
          font-size: 0.68rem;
          font-weight: 800;
          background: #d1fae5;
          color: #065f46;
          border: 1px solid #a7f3d0;
          letter-spacing: 0.03em;
        }

        .brand-subtitle {
          font-size: 0.75rem;
          color: #64748b;
          font-weight: 500;
          margin-top: 1px;
        }

        .officer-section {
          display: flex;
          align-items: center;
          gap: 14px;
        }

        .live-status-pill {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 5px 12px;
          background: #ecfdf5;
          border: 1px solid #a7f3d0;
          border-radius: 9999px;
        }

        .live-text {
          font-size: 0.72rem;
          font-weight: 700;
          color: #047857;
        }

        .icon-button {
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #e2e8f0;
          color: #475569;
          width: 36px;
          height: 36px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          box-shadow: 0 2px 5px rgba(0, 0, 0, 0.03);
          transition: all 0.2s ease;
        }

        .icon-button:hover {
          background: #ffffff;
          color: #0f172a;
          border-color: #cbd5e1;
          transform: rotate(45deg);
        }

        .officer-card {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 5px 12px;
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          box-shadow: 0 2px 8px rgba(15, 23, 42, 0.04);
        }

        .officer-avatar {
          width: 32px;
          height: 32px;
          border-radius: 50%;
          background: #0f172a;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 0.72rem;
          font-weight: 800;
          color: #ffffff;
          letter-spacing: 0.05em;
          border: 1.5px solid #ffffff;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .officer-info {
          display: flex;
          flex-direction: column;
        }

        .officer-name-row {
          display: flex;
          align-items: center;
          gap: 4px;
        }

        .text-emerald {
          color: #059669;
        }

        .officer-name {
          font-size: 0.82rem;
          font-weight: 700;
          color: #0f172a;
        }

        .officer-id {
          font-size: 0.68rem;
          font-family: var(--font-mono);
          color: #64748b;
          font-weight: 500;
        }
      `}</style>
    </header>
  );
};
