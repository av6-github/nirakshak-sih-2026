'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Shield, CheckCircle, XCircle, RefreshCw, LogOut,
  Search, Filter, MapPin, Package, AlertTriangle, FileText, Check, X, History
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  fetchReviewQueue,
  fetchComplaintsQueue,
  submitScanReview,
  submitComplaintReview,
  fetchManufacturerHistory,
  searchProducts,
  fetchProductHistory,
  fetchManufacturerRatings,
  rateManufacturer
} from '@/lib/api';
import Chatbot from '@/components/Chatbot';
import DetailsModal from '@/components/DetailsModal';

export default function Dashboard() {
  const router = useRouter();
  const [officer, setOfficer] = useState<any>(null);
  const [queue, setQueue] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('QUEUE'); // 'QUEUE' or 'AUDIT_HUB'
  const [activeFilter, setActiveFilter] = useState('ALL');
  const [groupBy, setGroupBy] = useState<'STATUS' | 'MANUFACTURER'>('STATUS');

  // Modal state for Manufacturer
  const [mfgHistory, setMfgHistory] = useState<any>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);

  // Audit Hub State
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<any>(null);
  const [isProductModalOpen, setIsProductModalOpen] = useState(false);
  const [selectedDetailsItem, setSelectedDetailsItem] = useState<any>(null);

  // Trust Portal State
  const [trustRatings, setTrustRatings] = useState<any[]>([]);
  const [isTrustLoading, setIsTrustLoading] = useState(false);
  const [ratingModal, setRatingModal] = useState<{ name: string; current: string | null } | null>(null);
  const [ratingNotes, setRatingNotes] = useState('');

  const [fullScreenImage, setFullScreenImage] = useState<string | null>(null);

  useEffect(() => {
    const user = localStorage.getItem('user');
    if (!user) {
      router.push('/');
      return;
    }
    setOfficer(JSON.parse(user));
    loadQueue();
  }, [router]);

  const loadQueue = async () => {
    setIsLoading(true);
    try {
      const [scans, complaints] = await Promise.all([
        fetchReviewQueue(),
        fetchComplaintsQueue(),
      ]);

      const combined = [
        ...scans.map((s: any) => ({ ...s, itemType: 'SCAN' })),
        ...complaints.map((c: any) => ({ ...c, itemType: 'COMPLAINT' }))
      ].sort((a, b) => new Date(b.created_at || '').getTime() - new Date(a.created_at || '').getTime());

      setQueue(combined);
    } catch (error) {
      console.error('Failed to load queue:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAction = async (item: any, action: string) => {
    try {
      if (item.itemType === 'COMPLAINT') {
        const status = action === 'ACCEPT' ? 'RESOLVED' : 'REJECTED';
        await submitComplaintReview(item.complaint_id, officer.id, status);
      } else {
        await submitScanReview(item.scan_id, officer.id, action);
      }
      loadQueue();
    } catch (error) {
      console.error('Error submitting review:', error);
    }
  };

  const handleViewHistory = async (manufacturerName: string) => {
    setIsModalOpen(true);
    setIsLoadingHistory(true);
    try {
      const data = await fetchManufacturerHistory(manufacturerName);
      setMfgHistory(data);
    } catch (error) {
      console.error('Failed to load history', error);
      setMfgHistory({ error: 'Failed to load data.' });
    } finally {
      setIsLoadingHistory(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('user');
    router.push('/');
  };

  const filteredQueue = queue.filter(item => {
    if (activeFilter === 'ALL') return true;
    if (activeFilter === 'SCANS' && item.itemType === 'SCAN') return true;
    if (activeFilter === 'COMPLAINTS' && item.itemType === 'COMPLAINT') return true;
    return false;
  });

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;
    setIsSearching(true);
    try {
      const results = await searchProducts(searchQuery);
      setSearchResults(results);
    } catch (error) {
      console.error('Search failed:', error);
    } finally {
      setIsSearching(false);
    }
  };

  const handleViewProduct = async (productId: string) => {
    setIsProductModalOpen(true);
    setIsLoadingHistory(true);
    try {
      const data = await fetchProductHistory(productId);
      setSelectedProduct(data);
    } catch (error) {
      console.error('Failed to load product history', error);
      setSelectedProduct({ error: 'Failed to load product data.' });
    } finally {
      setIsLoadingHistory(false);
    }
  };

  const generateReport = async (item: any) => {
    try {
      const html2pdf = (await import('html2pdf.js')).default;

      const element = document.createElement('div');
      element.innerHTML = `
        <div style="font-family: sans-serif; padding: 40px; color: #1e293b;">
          <div style="text-align: center; border-bottom: 2px solid #cbd5e1; padding-bottom: 20px; margin-bottom: 30px;">
            <h1 style="color: #0369a1; margin: 0;">NIRIKSHAK AI</h1>
            <h2 style="color: #475569; margin: 5px 0 0 0;">Official Enforcement Report</h2>
          </div>
          <div style="margin-bottom: 20px;">
            <p><strong>Report ID:</strong> ${item.itemType === 'COMPLAINT' ? item.complaint_id : item.scan_id}</p>
            <p><strong>Date Generated:</strong> ${new Date().toLocaleString()}</p>
            <p><strong>Status:</strong> ${item.overall_compliance || item.status}</p>
          </div>
          ${item.itemType === 'COMPLAINT' ? `
            <div style="background-color: #f1f5f9; padding: 20px; border-radius: 8px;">
              <h3 style="margin-top: 0; color: #334155;">Citizen Complaint Details</h3>
              <p><strong>Shopkeeper:</strong> ${item.shopkeeper_name || 'Unknown'}</p>
              <p><strong>Address:</strong> ${item.shop_address || 'Unknown'}</p>
              <p><strong>Paid Price:</strong> ₹${item.paid_price}</p>
              <p><strong>Printed MRP:</strong> ₹${item.printed_mrp}</p>
              <p><strong>Description:</strong> ${item.description || 'N/A'}</p>
            </div>
          ` : `
            <div style="background-color: #f1f5f9; padding: 20px; border-radius: 8px;">
              <h3 style="margin-top: 0; color: #334155;">AI Inspection Findings</h3>
              <p><strong>Manufacturer:</strong> ${item.manufacturer_name || 'Unknown'}</p>
              <p><strong>Product Name:</strong> ${item.product_name || 'Unknown'}</p>
              <p><strong>AI Reason:</strong> ${item.reason || 'Flagged for review.'}</p>
            </div>
          `}
          <div style="margin-top: 50px; border-top: 1px dashed #cbd5e1; padding-top: 20px; text-align: center; color: #94a3b8; font-size: 12px;">
            <p>Generated by Nirikshak AI Officer Portal</p>
          </div>
        </div>
      `;

      const opt: any = {
        margin: 10,
        filename: `nirikshak_report_${item.itemType === 'COMPLAINT' ? item.complaint_id.split('-')[0] : item.scan_id.split('-')[0]}.pdf`,
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2 },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
      };

      html2pdf().set(opt).from(element).save();
    } catch (error) {
      console.error('Failed to generate PDF', error);
      alert('Failed to generate PDF. Check console for details.');
    }
  };

  const loadTrustRatings = async () => {
    setIsTrustLoading(true);
    try {
      const data = await fetchManufacturerRatings();
      setTrustRatings(data);
    } catch (e) {
      console.error('Failed to load trust ratings', e);
    } finally {
      setIsTrustLoading(false);
    }
  };

  const handleRate = async (name: string, rating: string) => {
    try {
      await rateManufacturer(name, officer.user_id, rating, ratingNotes);
      setRatingModal(null);
      setRatingNotes('');
      loadTrustRatings();
    } catch (e) {
      console.error('Failed to submit rating', e);
    }
  };

  if (!officer) return null;

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col relative overflow-hidden">
      {/* Background Orbs */}
      <div className="absolute top-[-20%] left-[10%] w-[50%] h-[50%] rounded-full bg-cyan-600/10 blur-[150px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-indigo-600/10 blur-[150px] pointer-events-none" />

      {/* Header */}
      <header className="glass border-b border-slate-700/50 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-cyan-400 to-blue-600 flex items-center justify-center shadow-[0_0_15px_rgba(6,182,212,0.4)]">
              <Shield className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-lg leading-tight bg-clip-text text-transparent bg-gradient-to-r from-cyan-400 to-blue-400">NIRIKSHAK AI</h1>
              <p className="text-xs text-slate-400">Enforcement Control Center</p>
            </div>
          </div>

          <div className="flex items-center space-x-6">
            <div className="flex space-x-1 bg-slate-800/50 p-1 rounded-xl border border-slate-700/50">
              <button
                onClick={() => setActiveTab('QUEUE')}
                className={`px-4 py-1.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'QUEUE' ? 'bg-cyan-500/20 text-cyan-400' : 'text-slate-400 hover:text-slate-200'}`}
              >
                Review Queue
              </button>
              <button
                onClick={() => setActiveTab('AUDIT_HUB')}
                className={`px-4 py-1.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'AUDIT_HUB' ? 'bg-indigo-500/20 text-indigo-400' : 'text-slate-400 hover:text-slate-200'}`}
              >
                Audit Hub
              </button>
              <button
                onClick={() => { setActiveTab('TRUST_PORTAL'); loadTrustRatings(); }}
                className={`px-4 py-1.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'TRUST_PORTAL' ? 'bg-emerald-500/20 text-emerald-400' : 'text-slate-400 hover:text-slate-200'}`}
              >
                Trust Portal
              </button>
              <button
                onClick={() => setActiveTab('REJECTED')}
                className={`px-4 py-1.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'REJECTED' ? 'bg-red-500/20 text-red-400' : 'text-slate-400 hover:text-slate-200'}`}
              >
                Rejected
              </button>
            </div>

            <div className="flex items-center space-x-3 bg-slate-800/80 px-4 py-2 rounded-full border border-slate-700">
              <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-sm text-slate-300 font-medium">{officer.name}</span>
            </div>
            <button onClick={handleLogout} className="text-slate-400 hover:text-white transition-colors">
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-7xl mx-auto w-full px-6 py-8 relative z-10 flex flex-col">
        {activeTab === 'QUEUE' ? (
          <>
            {/* Controls */}
            <div className="flex justify-between items-end mb-8">
              <div>
                <h2 className="text-2xl font-semibold mb-2">Pending Review Queue</h2>
                <div className="flex space-x-2">
                  {['ALL', 'SCANS', 'COMPLAINTS'].map(filter => (
                    <button
                      key={filter}
                      onClick={() => setActiveFilter(filter)}
                      className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all ${activeFilter === filter
                        ? 'bg-cyan-500/20 text-cyan-400 border border-cyan-500/50 shadow-[0_0_10px_rgba(6,182,212,0.2)]'
                        : 'bg-slate-800 text-slate-400 hover:bg-slate-700 border border-transparent'
                        }`}
                    >
                      {filter}
                    </button>
                  ))}
                </div>
              </div>
              <div className="flex items-center space-x-4">
                <div className="bg-slate-800 rounded-lg p-1 flex border border-slate-700">
                  <button
                    onClick={() => setGroupBy('STATUS')}
                    className={`px-3 py-1 text-xs font-semibold rounded-md transition-colors ${groupBy === 'STATUS' ? 'bg-cyan-500/20 text-cyan-400' : 'text-slate-400 hover:text-slate-300'}`}
                  >
                    By Status
                  </button>
                  <button
                    onClick={() => setGroupBy('MANUFACTURER')}
                    className={`px-3 py-1 text-xs font-semibold rounded-md transition-colors ${groupBy === 'MANUFACTURER' ? 'bg-cyan-500/20 text-cyan-400' : 'text-slate-400 hover:text-slate-300'}`}
                  >
                    By Brand
                  </button>
                </div>
                <button
                  onClick={loadQueue}
                  className="flex items-center space-x-2 text-sm text-slate-400 hover:text-cyan-400 transition-colors bg-slate-800 px-4 py-2 rounded-lg border border-slate-700 hover:border-cyan-500/50"
                >
                  <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-cyan-400' : ''}`} />
                  <span>Refresh</span>
                </button>
              </div>
            </div>

            {/* Queue List */}
            <div className="flex-1 overflow-y-auto pr-2 pb-20 space-y-4">
              {isLoading ? (
                <div className="flex justify-center items-center h-40">
                  <div className="w-8 h-8 border-4 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin" />
                </div>
              ) : filteredQueue.length === 0 ? (
                <div className="glass rounded-2xl p-12 text-center border-dashed">
                  <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto mb-4 opacity-50" />
                  <h3 className="text-xl font-medium text-slate-300">Queue is empty</h3>
                  <p className="text-slate-500 mt-2">All inspections and complaints have been processed.</p>
                </div>
              ) : (
                <AnimatePresence>
                  {(() => {
                    const sections = groupBy === 'STATUS'
                      ? ['PENDING', 'RESOLVED']
                      : Array.from(new Set(filteredQueue.map(item => item.itemType === 'COMPLAINT' ? (item.shopkeeper_name || 'Unknown Entity') : (item.manufacturer_name || 'Unknown Entity')))).sort();

                    return sections.map((section) => {
                      const sectionItems = filteredQueue.filter(item => {
                        if (groupBy === 'STATUS') {
                          const isResolved = item.itemType === 'COMPLAINT' ? item.status !== 'SUBMITTED' : item.is_resolved === true;
                          return section === 'PENDING' ? !isResolved : isResolved;
                        } else {
                          const name = item.itemType === 'COMPLAINT' ? (item.shopkeeper_name || 'Unknown Entity') : (item.manufacturer_name || 'Unknown Entity');
                          return name === section;
                        }
                      });

                      if (sectionItems.length === 0) return null;

                      return (
                        <div key={section} className="mb-8">
                          <h3 className="text-lg font-bold text-cyan-400 mb-4 border-b border-slate-700 pb-2 flex items-center space-x-2">
                            {groupBy === 'MANUFACTURER' ? <Package className="w-5 h-5 text-slate-400" /> : null}
                            <span>{groupBy === 'STATUS' ? (section === 'PENDING' ? 'Pending Requests' : 'Resolved Requests') : section}</span>
                          </h3>
                          <div className="space-y-4">
                            {sectionItems.map((item, idx) => {
                              const isResolved = item.itemType === 'COMPLAINT' ? item.status !== 'SUBMITTED' : item.is_resolved === true;
                              const status = item.overall_compliance || item.status;
                              const isFail = status === 'FAIL' || status === 'SUBMITTED';
                              const isComplaint = item.itemType === 'COMPLAINT';

                              return (
                                <motion.div
                                  initial={{ opacity: 0, y: 20 }}
                                  animate={{ opacity: 1, y: 0 }}
                                  exit={{ opacity: 0, scale: 0.95 }}
                                  transition={{ delay: idx * 0.05 }}
                                  key={isComplaint ? item.complaint_id : item.scan_id}
                                  className="glass-panel rounded-2xl p-6 relative group overflow-hidden cursor-pointer hover:border-cyan-500/50 transition-colors"
                                  onClick={() => setSelectedDetailsItem(item)}
                                >
                                  {/* Top strip colored based on severity */}
                                  <div className={`absolute top-0 left-0 w-full h-1 ${isResolved ? 'bg-slate-500/80' : (isFail ? 'bg-red-500/80' : 'bg-amber-500/80')}`} />

                                  <div className="flex justify-between items-start mb-4">
                                    <div className="flex items-center space-x-3">
                                      <div className={`p-2 rounded-lg ${isComplaint ? 'bg-indigo-500/20 text-indigo-400' : 'bg-slate-700 text-slate-300'}`}>
                                        {isComplaint ? <FileText className="w-5 h-5" /> : <Package className="w-5 h-5" />}
                                      </div>
                                      <div>
                                        <h3 className="font-semibold text-lg text-slate-200">
                                          {isComplaint ? 'Citizen Complaint' : 'AI Inspection Flag'}
                                        </h3>
                                        <p className="text-xs text-slate-400 font-mono">
                                          ID: {isComplaint ? item.complaint_id.split('-')[0] : item.scan_id.split('-')[0]} • {new Date(item.created_at).toLocaleString()}
                                        </p>
                                      </div>
                                    </div>

                                    <div className="flex items-center space-x-2">
                                      <button
                                        onClick={(e) => {
                                          e.stopPropagation();
                                          generateReport(item);
                                        }}
                                        className="px-3 py-1 rounded-full text-xs font-semibold bg-slate-800 text-slate-300 hover:text-white border border-slate-600 flex items-center space-x-1"
                                      >
                                        <FileText className="w-3 h-3" />
                                        <span>Report</span>
                                      </button>
                                      <div className={`px-3 py-1 rounded-full text-xs font-bold border ${isResolved ? 'bg-slate-500/10 text-slate-400 border-slate-500/30' :
                                        isFail ? 'bg-red-500/10 text-red-400 border-red-500/30' : 'bg-amber-500/10 text-amber-400 border-amber-500/30'
                                        }`}>
                                        {isResolved ? (item.decision || item.status) : status}
                                      </div>
                                    </div>
                                  </div>

                                  <div className="bg-slate-800/50 rounded-xl p-4 border border-slate-700 mb-5">
                                    {isComplaint ? (
                                      <div className="grid grid-cols-2 gap-4">
                                        <div>
                                          <div className="text-xs text-slate-400 mb-1 flex items-center"><MapPin className="w-3 h-3 mr-1" /> Shop Details</div>
                                          <div className="text-sm">{item.shopkeeper_name || 'Unknown'}</div>
                                          <div className="text-sm text-slate-300">{item.shop_address || 'No address provided'}</div>
                                        </div>
                                        <div>
                                          <div className="text-xs text-slate-400 mb-1 flex items-center"><AlertTriangle className="w-3 h-3 mr-1" /> Violation</div>
                                          <div className="flex items-end space-x-2">
                                            <span className="text-lg font-bold text-red-400">Paid: ₹{item.paid_price}</span>
                                            <span className="text-sm text-slate-400 line-through mb-1">MRP: ₹{item.printed_mrp}</span>
                                          </div>
                                          <div className="text-xs text-slate-300 mt-1 italic">"{item.description}"</div>
                                        </div>
                                        {(item.receipt_image_url || item.product_image_url) && (
                                          <div className="col-span-2 mt-2 border-t border-slate-700 pt-3">
                                            <div className="text-xs text-slate-400 mb-2 font-semibold">Attached Evidence:</div>
                                            <div className="flex space-x-4">
                                              {item.receipt_image_url && (
                                                <img src={`http://192.168.29.65:8080${item.receipt_image_url}`} alt="Receipt" className="h-20 w-auto rounded-lg object-cover cursor-pointer hover:opacity-80" onClick={(e) => { e.stopPropagation(); setFullScreenImage(`http://192.168.29.65:8080${item.receipt_image_url}`); }} />
                                              )}
                                              {item.product_image_url && (
                                                <img src={`http://192.168.29.65:8080${item.product_image_url}`} alt="Product" className="h-20 w-auto rounded-lg object-cover cursor-pointer hover:opacity-80" onClick={(e) => { e.stopPropagation(); setFullScreenImage(`http://192.168.29.65:8080${item.product_image_url}`); }} />
                                              )}
                                            </div>
                                          </div>
                                        )}
                                      </div>
                                    ) : (
                                      <div>
                                        <div className="text-xs text-slate-400 mb-1 flex items-center">
                                          {status === 'PASS' ? <Check className="w-3 h-3 mr-1 text-emerald-400" /> : <AlertTriangle className="w-3 h-3 mr-1 text-amber-400" />}
                                          {status === 'PASS' ? 'Evaluation Outcome' : 'AI Finding'}
                                        </div>
                                        <div className="text-sm text-slate-200">{item.reason || (status === 'PASS' ? 'Product is fully compliant.' : 'Flagged for manual review.')}</div>

                                        {item.image_urls && Object.keys(item.image_urls).length > 0 && (
                                          <div className="mt-3">
                                            <div className="text-xs text-slate-400 mb-2 font-semibold">Scan Photos:</div>
                                            <div className="flex space-x-3 overflow-x-auto">
                                              {Object.entries(item.image_urls).map(([key, url]) => (
                                                <div key={key} className="relative group/img cursor-pointer" onClick={(e) => { e.stopPropagation(); setFullScreenImage(`http://192.168.29.65:8080${url}`); }}>
                                                  <img src={`http://192.168.29.65:8080${url}`} alt={key} className="h-16 w-16 rounded-lg object-cover border border-slate-600 hover:border-emerald-500 transition-colors" />
                                                  <div className="absolute bottom-0 left-0 right-0 bg-black/60 text-[10px] text-center p-0.5 text-white">{key.toUpperCase()}</div>
                                                </div>
                                              ))}
                                            </div>
                                          </div>
                                        )}

                                        {item.manufacturer_name && (
                                          <button
                                            onClick={(e) => {
                                              e.stopPropagation();
                                              handleViewHistory(item.manufacturer_name);
                                            }}
                                            className="mt-3 flex items-center space-x-1 text-xs text-cyan-400 hover:text-cyan-300 bg-cyan-950/30 px-3 py-1.5 rounded-lg border border-cyan-800 transition-colors"
                                          >
                                            <History className="w-3.5 h-3.5" />
                                            <span>View {item.manufacturer_name} History</span>
                                          </button>
                                        )}
                                      </div>
                                    )}
                                  </div>

                                  {!isResolved && (
                                    <div className="flex space-x-3">
                                      <button
                                        onClick={(e) => { e.stopPropagation(); handleAction(item, 'ACCEPT'); }}
                                        className="flex-1 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 rounded-xl py-2.5 flex items-center justify-center space-x-2 transition-colors font-medium text-sm"
                                      >
                                        <Check className="w-4 h-4" />
                                        <span>VALIDATE & ACCEPT</span>
                                      </button>
                                      <button
                                        onClick={(e) => { e.stopPropagation(); handleAction(item, 'REJECT'); }}
                                        className="flex-1 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 rounded-xl py-2.5 flex items-center justify-center space-x-2 transition-colors font-medium text-sm"
                                      >
                                        <X className="w-4 h-4" />
                                        <span>REJECT</span>
                                      </button>
                                      {!isComplaint && (
                                        <button
                                          onClick={(e) => { e.stopPropagation(); handleAction(item, 'REQUEST_RESCAN'); }}
                                          className="flex-1 bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/30 rounded-xl py-2.5 flex items-center justify-center space-x-2 transition-colors font-medium text-sm"
                                        >
                                          <RefreshCw className="w-4 h-4" />
                                          <span>REQUIRE RESCAN</span>
                                        </button>
                                      )}
                                    </div>
                                  )}
                                </motion.div>
                              );
                            })}
                          </div>
                        </div>
                      );
                    });
                  })()}
                </AnimatePresence>
              )}
            </div>
          </>
        ) : activeTab === 'AUDIT_HUB' ? (
          <div className="flex flex-col h-full">
            <h2 className="text-2xl font-semibold mb-6">Product Audit Hub</h2>
            <form onSubmit={handleSearch} className="mb-8 flex space-x-4">
              <div className="relative flex-1">
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search by Product Name or Barcode..."
                  className="w-full bg-slate-800/50 border border-slate-700 rounded-xl px-4 py-3 pl-10 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all"
                />
                <Search className="w-5 h-5 text-slate-500 absolute left-3 top-3.5" />
              </div>
              <button
                type="submit"
                disabled={!searchQuery.trim() || isSearching}
                className="bg-indigo-600 hover:bg-indigo-500 text-white px-6 py-3 rounded-xl font-semibold transition-colors flex items-center space-x-2 disabled:bg-slate-700"
              >
                {isSearching ? <RefreshCw className="w-5 h-5 animate-spin" /> : <Search className="w-5 h-5" />}
                <span>Search</span>
              </button>
            </form>

            <div className="flex-1 overflow-y-auto">
              {searchResults.length === 0 ? (
                <div className="text-center py-20 text-slate-500">
                  <Search className="w-12 h-12 mx-auto mb-4 opacity-30" />
                  <p>Search for a product to view its complete digital twin history.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {searchResults.map((product) => (
                    <div key={product.product_id} onClick={() => handleViewProduct(product.product_id)} className="glass-panel rounded-xl p-5 cursor-pointer hover:border-indigo-500/50 transition-colors group">
                      <div className="flex justify-between items-start mb-2">
                        <h4 className="font-semibold text-lg text-slate-200 group-hover:text-indigo-400 transition-colors">{product.product_name}</h4>
                        <Package className="w-5 h-5 text-slate-500" />
                      </div>
                      <p className="text-xs text-slate-400 font-mono mb-3">Barcode: {product.barcode}</p>
                      <div className="text-sm text-slate-300">
                        <span className="text-slate-500">Brand:</span> {product.brand}<br />
                        <span className="text-slate-500">Mfg:</span> {product.manufacturer}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

        ) : activeTab === 'REJECTED' ? (
          <div className="flex flex-col h-full">
            <h2 className="text-2xl font-semibold mb-6 text-red-400">Rejected Products</h2>
            <p className="text-sm text-slate-400 mb-6">Products that have been reviewed and rejected by enforcement officers, grouped by manufacturer/brand.</p>
            {(() => {
              const rejectedItems = queue.filter((item: any) => item.decision === 'REJECT' || item.status === 'REJECTED');
              if (rejectedItems.length === 0) {
                return (
                  <div className="glass-panel rounded-2xl p-12 text-center border-dashed">
                    <XCircle className="w-12 h-12 text-red-500 mx-auto mb-4 opacity-50" />
                    <h3 className="text-xl font-medium text-slate-300">No rejected products</h3>
                    <p className="text-slate-500 mt-2">No products have been rejected yet.</p>
                  </div>
                );
              }

              const grouped: Record<string, any[]> = {};
              rejectedItems.forEach((item: any) => {
                const brand = item.manufacturer_name || item.shopkeeper_name || 'Unknown Brand';
                if (!grouped[brand]) grouped[brand] = [];
                grouped[brand].push(item);
              });

              return (
                <div className="flex-1 overflow-y-auto space-y-6 pb-20">
                  {Object.entries(grouped).sort(([a], [b]) => a.localeCompare(b)).map(([brand, items]) => (
                    <div key={brand} className="glass-panel rounded-2xl overflow-hidden">
                      <div className="bg-red-500/10 border-b border-red-500/20 px-6 py-4 flex justify-between items-center">
                        <div className="flex items-center space-x-3">
                          <Package className="w-5 h-5 text-red-400" />
                          <h3 className="text-lg font-bold text-red-400">{brand}</h3>
                        </div>
                        <span className="bg-red-500/20 text-red-400 px-3 py-1 rounded-full text-xs font-bold">
                          {items.length} rejected
                        </span>
                      </div>
                      <div className="divide-y divide-slate-800">
                        {items.map((item: any, idx: number) => {
                          const isComplaint = item.itemType === 'COMPLAINT';
                          const id = isComplaint ? item.complaint_id : item.scan_id;
                          return (
                            <div
                              key={id || idx}
                              className="px-6 py-4 hover:bg-slate-800/30 cursor-pointer transition-colors"
                              onClick={() => setSelectedDetailsItem(item)}
                            >
                              <div className="flex justify-between items-start">
                                <div className="flex-1">
                                  <div className="flex items-center space-x-2 mb-1">
                                    <XCircle className="w-4 h-4 text-red-400" />
                                    <span className="text-sm font-semibold text-slate-200">
                                      {isComplaint ? 'Complaint' : 'AI Inspection'}
                                    </span>
                                    <span className="text-xs text-slate-500 font-mono">
                                      {id?.split('-')[0]}
                                    </span>
                                  </div>
                                  <p className="text-sm text-slate-400 ml-6">
                                    {item.reason || item.description || 'Rejected by enforcement officer.'}
                                  </p>
                                </div>
                                <div className="text-right ml-4 flex-shrink-0">
                                  <div className="text-xs text-slate-500">
                                    {item.created_at ? new Date(item.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : ''}
                                  </div>
                                  <div className="text-xs text-slate-600 mt-1">
                                    {item.created_at ? new Date(item.created_at).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) : ''}
                                  </div>
                                </div>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  ))}
                </div>
              );
            })()}
          </div>

        ) : (
          <div className="flex flex-col h-full">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-semibold">Manufacturer / Retailer Trust Portal</h2>
              <button onClick={loadTrustRatings} className="flex items-center space-x-2 text-sm text-slate-400 hover:text-emerald-400 transition-colors bg-slate-800 px-4 py-2 rounded-lg border border-slate-700">
                <RefreshCw className={`w-4 h-4 ${isTrustLoading ? 'animate-spin' : ''}`} />
                <span>Refresh</span>
              </button>
            </div>
            <p className="text-sm text-slate-400 mb-6">Officer-assigned trust ratings for manufacturers. These are <strong>NOT</strong> raw AI scores — only enforcement officers can assign RED / YELLOW / GREEN ratings.</p>

            {isTrustLoading ? (
              <div className="flex justify-center items-center h-40">
                <div className="w-8 h-8 border-4 border-emerald-500/30 border-t-emerald-500 rounded-full animate-spin" />
              </div>
            ) : trustRatings.length === 0 ? (
              <div className="glass rounded-2xl p-12 text-center border-dashed">
                <Shield className="w-12 h-12 text-emerald-500 mx-auto mb-4 opacity-50" />
                <h3 className="text-xl font-medium text-slate-300">No manufacturers found</h3>
                <p className="text-slate-500 mt-2">Scan products to build the manufacturer database.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {trustRatings.map((mfr: any, idx: number) => {
                  const ratingColor = mfr.officer_rating === 'GREEN' ? 'emerald' : mfr.officer_rating === 'YELLOW' ? 'amber' : mfr.officer_rating === 'RED' ? 'red' : 'slate';
                  return (
                    <motion.div
                      key={mfr.manufacturer_name}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: idx * 0.05 }}
                      className="glass-panel rounded-xl p-5 group hover:border-emerald-500/30 transition-colors"
                    >
                      <div className="flex justify-between items-start mb-3">
                        <h4 className="font-semibold text-lg text-slate-200">{mfr.manufacturer_name}</h4>
                        {mfr.officer_rating ? (
                          <div className={`px-3 py-1 rounded-full text-xs font-bold bg-${ratingColor}-500/20 text-${ratingColor}-400 border border-${ratingColor}-500/30`}>
                            {mfr.officer_rating}
                          </div>
                        ) : (
                          <div className="px-3 py-1 rounded-full text-xs font-bold bg-slate-700 text-slate-400 border border-slate-600">
                            UNRATED
                          </div>
                        )}
                      </div>
                      <div className="grid grid-cols-2 gap-2 mb-3 text-sm">
                        <div><span className="text-slate-500">Total Scans:</span> <span className="text-slate-300">{mfr.total_scans}</span></div>
                        <div><span className="text-slate-500">Passed:</span> <span className="text-emerald-400">{mfr.passed_scans}</span></div>
                        <div><span className="text-slate-500">AI Score:</span> <span className="text-slate-300">{mfr.ai_compliance_score}%</span></div>
                        {mfr.last_rated_at && <div><span className="text-slate-500">Rated:</span> <span className="text-slate-300">{new Date(mfr.last_rated_at).toLocaleDateString()}</span></div>}
                      </div>
                      {mfr.officer_notes && <p className="text-xs text-slate-400 italic mb-3">"{mfr.officer_notes}"</p>}
                      <button
                        onClick={() => setRatingModal({ name: mfr.manufacturer_name, current: mfr.officer_rating })}
                        className="w-full mt-2 bg-slate-800 hover:bg-slate-700 text-slate-300 py-2 rounded-lg text-sm font-medium border border-slate-600 transition-colors"
                      >
                        {mfr.officer_rating ? 'Update Rating' : 'Assign Rating'}
                      </button>
                    </motion.div>
                  );
                })}
              </div>
            )}
          </div>
        )}
      </main>

      {/* Rating Modal */}
      <AnimatePresence>
        {ratingModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm" onClick={() => setRatingModal(null)} />
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="glass-panel w-full max-w-md rounded-2xl p-6 relative z-10">
              <h3 className="text-xl font-semibold text-emerald-400 mb-4">Rate: {ratingModal.name}</h3>
              <p className="text-sm text-slate-400 mb-4">Assign an official officer trust rating. Current: <strong>{ratingModal.current || 'UNRATED'}</strong></p>
              <div className="flex space-x-3 mb-4">
                {['GREEN', 'YELLOW', 'RED'].map(r => (
                  <button
                    key={r}
                    onClick={() => handleRate(ratingModal.name, r)}
                    className={`flex-1 py-3 rounded-xl text-sm font-bold border transition-all ${r === 'GREEN' ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/50 hover:bg-emerald-500/30' :
                      r === 'YELLOW' ? 'bg-amber-500/20 text-amber-400 border-amber-500/50 hover:bg-amber-500/30' :
                        'bg-red-500/20 text-red-400 border-red-500/50 hover:bg-red-500/30'
                      }`}
                  >
                    {r}
                  </button>
                ))}
              </div>
              <textarea
                value={ratingNotes}
                onChange={(e) => setRatingNotes(e.target.value)}
                placeholder="Optional notes..."
                className="w-full bg-slate-800 border border-slate-700 rounded-lg p-3 text-sm text-white placeholder-slate-500 mb-4 focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
                rows={2}
              />
              <button onClick={() => setRatingModal(null)} className="w-full text-slate-400 hover:text-white py-2 text-sm">Cancel</button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Manufacturer History Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm"
              onClick={() => setIsModalOpen(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="glass-panel w-full max-w-2xl rounded-2xl overflow-hidden relative z-10 shadow-2xl flex flex-col max-h-[80vh]"
            >
              <div className="px-6 py-4 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/50">
                <h3 className="text-xl font-semibold text-cyan-400">Manufacturer Audit History</h3>
                <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-white">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="p-6 flex-1 overflow-y-auto">
                {isLoadingHistory ? (
                  <div className="flex justify-center items-center h-40">
                    <div className="w-8 h-8 border-4 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin" />
                  </div>
                ) : mfgHistory?.error ? (
                  <div className="text-red-400 text-center py-8">{mfgHistory.error}</div>
                ) : (
                  <>
                    <div className="flex space-x-6 mb-8">
                      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex-1">
                        <div className="text-sm text-slate-400 mb-1">Entity Name</div>
                        <div className="text-lg font-bold">{mfgHistory.manufacturer_name}</div>
                      </div>
                      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex-1">
                        <div className="text-sm text-slate-400 mb-1">Total Scans</div>
                        <div className="text-2xl font-bold">{mfgHistory.total_scans}</div>
                      </div>
                      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex-1 relative overflow-hidden">
                        <div className={`absolute bottom-0 left-0 h-1 bg-gradient-to-r ${mfgHistory.compliance_score > 80 ? 'from-emerald-500 to-green-400' : 'from-red-500 to-orange-400'}`} style={{ width: `${mfgHistory.compliance_score}%` }} />
                        <div className="text-sm text-slate-400 mb-1">Compliance Score</div>
                        <div className={`text-2xl font-bold ${mfgHistory.compliance_score > 80 ? 'text-emerald-400' : 'text-red-400'}`}>
                          {mfgHistory.compliance_score}%
                        </div>
                      </div>
                    </div>

                    <h4 className="text-sm font-semibold text-slate-300 mb-3 border-b border-slate-700 pb-2">Chronological Inspections History</h4>
                    <div className="space-y-4">
                      {mfgHistory.history?.length === 0 ? (
                        <div className="text-slate-500 italic">No historical records found.</div>
                      ) : (
                        Object.entries(
                          mfgHistory.history?.reduce((acc: any, record: any) => {
                            const date = new Date(record.date).toLocaleDateString(undefined, { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' });
                            if (!acc[date]) acc[date] = [];
                            acc[date].push(record);
                            return acc;
                          }, {}) || {}
                        ).map(([date, records]: any, dateIdx: number) => (
                          <div key={dateIdx} className="mb-4 relative pl-4 border-l-2 border-slate-700">
                            <div className="absolute w-3 h-3 bg-cyan-500 rounded-full -left-[7px] top-1 border-2 border-slate-900"></div>
                            <h5 className="text-xs font-bold text-cyan-400 uppercase tracking-wider mb-3">{date}</h5>
                            <div className="space-y-2">
                              {records.map((record: any, idx: number) => (
                                <div key={idx} className="flex justify-between items-center p-3 rounded-xl bg-slate-800/40 border border-slate-700/50 hover:bg-slate-700/50 transition-colors">
                                  <div>
                                    <div className="font-medium text-sm text-slate-200">{record.product_name}</div>
                                    <div className="text-xs text-slate-400 mt-1">{new Date(record.date).toLocaleTimeString()}</div>
                                  </div>
                                  <div className={`px-2 py-1 rounded text-xs font-bold ${record.status === 'PASS' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'}`}>
                                    {record.status}
                                  </div>
                                </div>
                              ))}
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Product History Modal */}
      <AnimatePresence>
        {isProductModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm"
              onClick={() => setIsProductModalOpen(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="glass-panel w-full max-w-2xl rounded-2xl overflow-hidden relative z-10 shadow-2xl flex flex-col max-h-[80vh]"
            >
              <div className="px-6 py-4 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/50">
                <h3 className="text-xl font-semibold text-indigo-400">Product Digital Twin History</h3>
                <button onClick={() => setIsProductModalOpen(false)} className="text-slate-400 hover:text-white">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="p-6 flex-1 overflow-y-auto">
                {isLoadingHistory ? (
                  <div className="flex justify-center items-center h-40">
                    <div className="w-8 h-8 border-4 border-indigo-500/30 border-t-indigo-500 rounded-full animate-spin" />
                  </div>
                ) : selectedProduct?.error ? (
                  <div className="text-red-400 text-center py-8">{selectedProduct.error}</div>
                ) : (
                  <>
                    <div className="flex space-x-6 mb-8">
                      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex-1">
                        <div className="text-sm text-slate-400 mb-1">Product Name</div>
                        <div className="text-lg font-bold">{selectedProduct.product_name}</div>
                      </div>
                      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex-1 relative overflow-hidden">
                        <div className={`absolute bottom-0 left-0 h-1 bg-gradient-to-r ${selectedProduct.trust_score > 80 ? 'from-emerald-500 to-green-400' : 'from-red-500 to-orange-400'}`} style={{ width: `${selectedProduct.trust_score}%` }} />
                        <div className="text-sm text-slate-400 mb-1">Trust Score</div>
                        <div className={`text-2xl font-bold ${selectedProduct.trust_score > 80 ? 'text-emerald-400' : 'text-red-400'}`}>
                          {selectedProduct.trust_score}%
                        </div>
                      </div>
                    </div>

                    <h4 className="text-sm font-semibold text-slate-300 mb-3 border-b border-slate-700 pb-2">Scan Timeline</h4>
                    <div className="space-y-3">
                      {selectedProduct.compliance_timeline?.length === 0 ? (
                        <div className="text-slate-500 italic">No historical records found.</div>
                      ) : (
                        selectedProduct.compliance_timeline?.map((record: any, idx: number) => (
                          <div key={idx} className="flex justify-between items-center p-3 rounded-xl bg-slate-800/30 border border-slate-700/50">
                            <div>
                              <div className="font-medium text-sm">Scan {record.scan_id.split('-')[0]}</div>
                              <div className="text-xs text-slate-400 mt-1">{new Date(record.created_at).toLocaleString()}</div>
                            </div>
                            <div className={`px-2 py-1 rounded text-xs font-bold ${record.overall_compliance === 'PASS' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'}`}>
                              {record.overall_compliance || 'UNKNOWN'}
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Full Screen Image Viewer Modal */}
      <AnimatePresence>
        {fullScreenImage && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/95 backdrop-blur-md" onClick={() => setFullScreenImage(null)}>
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }}
              className="relative w-full h-full flex items-center justify-center p-4"
            >
              <button
                onClick={(e) => { e.stopPropagation(); setFullScreenImage(null); }}
                className="absolute top-6 right-6 p-2 bg-slate-800 hover:bg-slate-700 rounded-full text-white transition-colors"
              >
                <X className="w-6 h-6" />
              </button>
              <img src={fullScreenImage} alt="Full Screen" className="max-w-full max-h-full object-contain rounded-lg shadow-2xl" />
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <Chatbot />

      {selectedDetailsItem && (
        <DetailsModal
          item={selectedDetailsItem}
          onClose={() => setSelectedDetailsItem(null)}
        />
      )}
    </div>
  );
}
