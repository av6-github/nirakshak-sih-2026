'use client';

import React, { useState, useEffect } from 'react';
import { Header } from '../components/Header';
import { Sidebar, TabType } from '../components/Sidebar';
import { ComplaintsTab } from '../components/ComplaintsTab';
import { ScanHistoryTab } from '../components/ScanHistoryTab';
import { BrandReportTab } from '../components/BrandReportTab';
import { LegalChatTab } from '../components/LegalChatTab';
import { ReportsTab } from '../components/ReportsTab';
import { EvidenceModal } from '../components/EvidenceModal';
import { OfficerApi } from '../services/api';
import { Complaint, ScanItem, BrandRating } from '../types';
import { 
  AlertTriangle, 
  Scan, 
  Building2, 
  FileCheck2,
} from 'lucide-react';

export default function OfficerDashboard() {
  const [currentTab, setCurrentTab] = useState<TabType>('complaints');
  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [scans, setScans] = useState<ScanItem[]>([]);
  const [brands, setBrands] = useState<BrandRating[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // Modal Evidence state
  const [modalOpen, setModalOpen] = useState(false);
  const [modalTitle, setModalTitle] = useState('');
  const [modalReceiptUrl, setModalReceiptUrl] = useState<string | undefined>();
  const [modalProductUrl, setModalProductUrl] = useState<string | undefined>();
  const [modalDescription, setModalDescription] = useState<string | undefined>();
  const [modalNotes, setModalNotes] = useState<string | undefined>();

  const loadAllData = async () => {
    setLoading(true);
    const [cData, sData, bData] = await Promise.all([
      OfficerApi.getComplaints(),
      OfficerApi.getScanHistory(),
      OfficerApi.getBrandRatings(),
    ]);
    setComplaints(cData);
    setScans(sData);
    setBrands(bData);
    setLoading(false);
  };

  useEffect(() => {
    loadAllData();
  }, []);

  const openEvidenceModal = (
    title: string,
    receipt?: string,
    product?: string,
    desc?: string,
    notes?: string
  ) => {
    setModalTitle(title);
    setModalReceiptUrl(receipt);
    setModalProductUrl(product);
    setModalDescription(desc);
    setModalNotes(notes);
    setModalOpen(true);
  };

  const pendingComplaints = complaints.filter(
    (c) => c.status === 'SUBMITTED' || c.status === 'UNDER_REVIEW'
  ).length;

  const totalViolationsDetected = scans.reduce(
    (acc, s) => acc + (s.compliance_summary?.failed_rules || (s.overall_compliance === 'FAIL' ? 1 : 0)),
    0
  );

  return (
    <div className="dashboard-root">
      {/* Top Header */}
      <Header onRefresh={loadAllData} activeTabTitle={currentTab} />

      {/* Main Workspace Layout */}
      <div className="workspace-layout">
        {/* Sidebar Nav */}
        <Sidebar
          currentTab={currentTab}
          onSelectTab={(tab) => setCurrentTab(tab)}
          pendingComplaintsCount={pendingComplaints}
          totalScansCount={scans.length}
        />

        {/* Content Area */}
        <main className="content-area">
          {/* Quick Metrics Bar (Glass Card matching mobile) */}
          <div className="metrics-banner glass-panel">
            <div className="metric-cell" onClick={() => setCurrentTab('complaints')}>
              <div className="cell-icon crimson">
                <AlertTriangle size={18} />
              </div>
              <div className="cell-info">
                <span className="cell-val font-mono text-crimson">{pendingComplaints}</span>
                <span className="cell-lbl">Pending Overcharge Grievances</span>
              </div>
            </div>

            <div className="metric-divider"></div>

            <div className="metric-cell" onClick={() => setCurrentTab('scans')}>
              <div className="cell-icon cyan">
                <Scan size={18} />
              </div>
              <div className="cell-info">
                <span className="cell-val font-mono">{scans.length}</span>
                <span className="cell-lbl">Field Inspections Logged</span>
              </div>
            </div>

            <div className="metric-divider"></div>

            <div className="metric-cell" onClick={() => setCurrentTab('brands')}>
              <div className="cell-icon emerald">
                <Building2 size={18} />
              </div>
              <div className="cell-info">
                <span className="cell-val font-mono text-emerald">{brands.length}</span>
                <span className="cell-lbl">Manufacturer Profiles</span>
              </div>
            </div>

            <div className="metric-divider"></div>

            <div className="metric-cell" onClick={() => setCurrentTab('reports')}>
              <div className="cell-icon amber">
                <FileCheck2 size={18} />
              </div>
              <div className="cell-info">
                <span className="cell-val font-mono">{totalViolationsDetected}</span>
                <span className="cell-lbl">Statutory Non-Compliances</span>
              </div>
            </div>
          </div>

          {/* Tab Content Panels */}
          <div className="tab-render-container">
            {currentTab === 'complaints' && (
              <ComplaintsTab
                complaints={complaints}
                onRefresh={loadAllData}
                onOpenEvidence={openEvidenceModal}
              />
            )}

            {currentTab === 'scans' && (
              <ScanHistoryTab scans={scans} onRefresh={loadAllData} />
            )}

            {currentTab === 'brands' && (
              <BrandReportTab brands={brands} onRefresh={loadAllData} />
            )}

            {currentTab === 'chat' && <LegalChatTab />}

            {currentTab === 'reports' && (
              <ReportsTab complaints={complaints} scans={scans} />
            )}
          </div>
        </main>
      </div>

      {/* Photo Evidence Modal */}
      <EvidenceModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={modalTitle}
        receiptUrl={modalReceiptUrl}
        productUrl={modalProductUrl}
        description={modalDescription}
        notes={modalNotes}
      />

      <style jsx>{`
        .dashboard-root {
          min-height: 100vh;
          display: flex;
          flex-direction: column;
          position: relative;
          z-index: 1;
        }

        .workspace-layout {
          display: flex;
          flex: 1;
          height: calc(100vh - 66px);
          overflow: hidden;
        }

        .content-area {
          flex: 1;
          padding: 18px 24px;
          overflow-y: auto;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .metrics-banner {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 12px 24px;
          background: rgba(255, 255, 255, 0.75);
          backdrop-filter: blur(16px);
          border: 1px solid rgba(255, 255, 255, 0.9);
          box-shadow: 0 4px 20px rgba(15, 23, 42, 0.04);
        }

        .metric-cell {
          display: flex;
          align-items: center;
          gap: 12px;
          cursor: pointer;
          transition: transform 0.15s ease;
        }

        .metric-cell:hover {
          transform: translateY(-1px);
        }

        .cell-icon {
          width: 38px;
          height: 38px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .cell-icon.crimson {
          background: #fee2e2;
          color: #dc2626;
        }

        .cell-icon.cyan {
          background: #e0f2fe;
          color: #0284c7;
        }

        .cell-icon.emerald {
          background: #d1fae5;
          color: #059669;
        }

        .cell-icon.amber {
          background: #fef3c7;
          color: #d97706;
        }

        .cell-info {
          display: flex;
          flex-direction: column;
        }

        .cell-val {
          font-size: 1.3rem;
          font-weight: 800;
          color: #0f172a;
        }

        .cell-lbl {
          font-size: 0.72rem;
          color: #64748b;
          font-weight: 500;
        }

        .metric-divider {
          width: 1px;
          height: 28px;
          background: #e2e8f0;
        }

        .tab-render-container {
          flex: 1;
        }

        .text-crimson {
          color: #dc2626;
        }

        .text-emerald {
          color: #059669;
        }
      `}</style>
    </div>
  );
}
