'use client';

import React from 'react';
import { 
  AlertTriangle, 
  Scan, 
  Building2, 
  Bot, 
  FileCheck2, 
  Activity,
  ChevronRight
} from 'lucide-react';

export type TabType = 'complaints' | 'scans' | 'brands' | 'chat' | 'reports';

interface SidebarProps {
  currentTab: TabType;
  onSelectTab: (tab: TabType) => void;
  pendingComplaintsCount: number;
  totalScansCount: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  pendingComplaintsCount,
  totalScansCount,
}) => {
  const navItems = [
    {
      id: 'complaints' as TabType,
      label: 'Citizen Complaints',
      subtitle: 'Rule 18(2) Overcharge Redressal',
      icon: <AlertTriangle size={18} />,
      badge: pendingComplaintsCount > 0 ? `${pendingComplaintsCount} New` : undefined,
      badgeColor: 'badge-crimson',
    },
    {
      id: 'scans' as TabType,
      label: 'Field Officer Scans',
      subtitle: 'Live Product Inspection Audit',
      icon: <Scan size={18} />,
      badge: `${totalScansCount} Scans`,
      badgeColor: 'badge-cyan',
    },
    {
      id: 'brands' as TabType,
      label: 'Brand Intelligence',
      subtitle: 'Compliance Matrix & Trust Ratings',
      icon: <Building2 size={18} />,
      badge: undefined,
      badgeColor: undefined,
    },
    {
      id: 'chat' as TabType,
      label: 'AI Legal Counsel',
      subtitle: 'RAG LMPC 2011 Knowledgebase',
      icon: <Bot size={18} />,
      badge: 'RAG V2',
      badgeColor: 'badge-emerald',
    },
    {
      id: 'reports' as TabType,
      label: 'Report Generation',
      subtitle: 'Certified Statutory Notices & PDFs',
      icon: <FileCheck2 size={18} />,
      badge: undefined,
      badgeColor: undefined,
    },
  ];

  return (
    <aside className="sidebar-container">
      <div className="section-label">ENFORCEMENT MODULES</div>
      
      <nav className="nav-list">
        {navItems.map((item) => {
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              className={`nav-button ${isActive ? 'active' : ''}`}
            >
              <div className="nav-icon-container">
                {item.icon}
              </div>
              <div className="nav-text-container">
                <div className="nav-label-row">
                  <span className="nav-label">{item.label}</span>
                  {item.badge && (
                    <span className={`badge ${item.badgeColor} pill-badge`}>
                      {item.badge}
                    </span>
                  )}
                </div>
                <span className="nav-subtitle">{item.subtitle}</span>
              </div>
              <ChevronRight size={14} className={`arrow-icon ${isActive ? 'visible' : ''}`} />
            </button>
          );
        })}
      </nav>

      <div className="system-status-card">
        <div className="status-header">
          <Activity size={14} className="text-emerald" />
          <span className="status-title">STATUTORY PIPELINE</span>
        </div>
        <p className="status-desc">
          Automated OCR extraction, cross-referencing Schedule-II font sizes and Rule 18(2) dual-pricing verification active.
        </p>
        <div className="status-meta">
          <span className="font-mono">DB: PostgreSQL Active</span>
          <span className="font-mono">ChromaDB: Connected</span>
        </div>
      </div>

      <style jsx>{`
        .sidebar-container {
          width: 300px;
          min-width: 300px;
          background: rgba(255, 255, 255, 0.65);
          backdrop-filter: blur(16px);
          -webkit-backdrop-filter: blur(16px);
          border-right: 1px solid rgba(255, 255, 255, 0.85);
          padding: 22px 14px;
          display: flex;
          flex-direction: column;
          gap: 14px;
          z-index: 10;
        }

        .section-label {
          font-size: 0.68rem;
          font-weight: 800;
          letter-spacing: 0.08em;
          color: #64748b;
          padding-left: 10px;
        }

        .nav-list {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .nav-button {
          width: 100%;
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 11px 12px;
          background: transparent;
          border: 1px solid transparent;
          border-radius: 12px;
          color: #475569;
          cursor: pointer;
          transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
          text-align: left;
          font-family: var(--font-outfit);
        }

        .nav-button:hover {
          background: rgba(255, 255, 255, 0.8);
          border-color: rgba(255, 255, 255, 0.9);
          color: #0f172a;
          box-shadow: 0 2px 8px rgba(15, 23, 42, 0.04);
        }

        .nav-button.active {
          background: #0f172a;
          border-color: #0f172a;
          color: #ffffff;
          box-shadow: 0 4px 16px rgba(15, 23, 42, 0.18);
        }

        .nav-icon-container {
          color: #64748b;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: color 0.2s;
        }

        .nav-button:hover .nav-icon-container {
          color: #059669;
        }

        .nav-button.active .nav-icon-container {
          color: #34d399;
        }

        .nav-text-container {
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .nav-label-row {
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .nav-label {
          font-size: 0.88rem;
          font-weight: 700;
        }

        .pill-badge {
          font-size: 0.65rem;
          padding: 2px 7px;
        }

        .nav-subtitle {
          font-size: 0.72rem;
          color: #64748b;
          font-weight: 500;
        }

        .nav-button.active .nav-subtitle {
          color: #94a3b8;
        }

        .arrow-icon {
          opacity: 0;
          color: #34d399;
          transition: opacity 0.2s, transform 0.2s;
        }

        .arrow-icon.visible {
          opacity: 1;
          transform: translateX(2px);
        }

        .system-status-card {
          margin-top: auto;
          background: rgba(255, 255, 255, 0.75);
          border: 1px solid rgba(255, 255, 255, 0.9);
          border-radius: 14px;
          padding: 13px;
          box-shadow: 0 4px 16px rgba(15, 23, 42, 0.04);
        }

        .status-header {
          display: flex;
          align-items: center;
          gap: 6px;
          margin-bottom: 5px;
        }

        .text-emerald {
          color: #059669;
        }

        .status-title {
          font-size: 0.72rem;
          font-weight: 800;
          letter-spacing: 0.05em;
          color: #0f172a;
        }

        .status-desc {
          font-size: 0.72rem;
          color: #475569;
          line-height: 1.4;
          margin-bottom: 8px;
        }

        .status-meta {
          display: flex;
          flex-direction: column;
          gap: 3px;
          font-size: 0.65rem;
          color: #64748b;
          border-top: 1px solid #e2e8f0;
          padding-top: 6px;
        }
      `}</style>
    </aside>
  );
};
