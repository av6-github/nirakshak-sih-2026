import React from 'react';
import { X, CheckCircle, AlertTriangle, ExternalLink, ShoppingCart, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const FlipCard = ({ evaluation }: { evaluation: any }) => {
  const [isFlipped, setIsFlipped] = React.useState(false);
  const isFail = evaluation.status === 'FAIL';
  
  return (
    <div 
      className="w-full h-40 cursor-pointer"
      style={{ perspective: 1000 }}
      onClick={() => setIsFlipped(!isFlipped)}
    >
      <motion.div
        className="w-full h-full relative duration-500"
        style={{ transformStyle: 'preserve-3d' }}
        initial={false}
        animate={{ rotateY: isFlipped ? 180 : 0 }}
      >
        {/* Front */}
        <div 
          className={`absolute inset-0 p-4 rounded-xl border flex flex-col justify-center items-center shadow-lg ${isFail ? 'bg-red-900/20 border-red-500/30' : 'bg-emerald-900/20 border-emerald-500/30'}`}
          style={{ backfaceVisibility: 'hidden' }}
        >
          {isFail ? <AlertTriangle className="w-8 h-8 text-red-400 mb-2" /> : <CheckCircle className="w-8 h-8 text-emerald-400 mb-2" />}
          <span className="font-semibold text-center text-sm text-slate-200">{evaluation.rule_title}</span>
          <span className="text-xs text-slate-500 mt-2">Tap to flip</span>
        </div>
        
        {/* Back */}
        <div 
          className={`absolute inset-0 p-4 rounded-xl border flex flex-col justify-center overflow-y-auto shadow-lg ${isFail ? 'bg-red-900/40 border-red-500/50' : 'bg-emerald-900/40 border-emerald-500/50'}`}
          style={{ backfaceVisibility: 'hidden', transform: 'rotateY(180deg)' }}
        >
          <p className="text-xs text-slate-200 font-medium mb-1">{evaluation.reason}</p>
          
          {isFail && evaluation.citation && (
            <div className="mt-2 border-t border-slate-700/50 pt-2 space-y-1">
              {(evaluation.citation.act_name || typeof evaluation.citation === 'string') && (
                <div className="text-[9px] font-bold text-red-300 uppercase tracking-wider bg-red-900/30 px-2 py-1 rounded inline-block">
                  ⚖ {evaluation.citation.act_name || 'Legal Reference'}
                </div>
              )}
              {(evaluation.citation.quote || typeof evaluation.citation === 'string') && (
                <p className="text-[10px] text-slate-400 italic">
                  "{evaluation.citation.quote || evaluation.citation}"
                </p>
              )}
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default function DetailsModal({ item, onClose }: { item: any, onClose: () => void }) {
  if (!item) return null;

  const isComplaint = item.itemType === 'COMPLAINT';
  const title = isComplaint ? 'Complaint Details' : 'Inspection Breakdown';

  return (
    <AnimatePresence>
      <motion.div 
        initial={{ opacity: 0 }} 
        animate={{ opacity: 1 }} 
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
      >
        <motion.div 
          initial={{ scale: 0.95, y: 20 }} 
          animate={{ scale: 1, y: 0 }} 
          exit={{ scale: 0.95, y: 20 }}
          className="bg-slate-900 border border-slate-700 rounded-2xl p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto"
        >
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold text-cyan-400">{title}</h2>
            <div className="flex items-center space-x-3">
              <a 
                href={isComplaint ? `http://192.168.29.65:8080/reports/complaint/${item.complaint_id}/download` : `http://192.168.29.65:8080/reports/${item.scan_id}/download`} 
                target="_blank" 
                rel="noopener noreferrer"
                className="px-4 py-2 bg-cyan-600/20 text-cyan-400 border border-cyan-500/30 rounded-lg text-sm font-semibold hover:bg-cyan-600/30 transition-colors"
              >
                Download PDF
              </a>
              <button onClick={onClose} className="p-2 bg-slate-800 rounded-full text-slate-400 hover:text-white hover:bg-slate-700 transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
              <h3 className="text-sm font-semibold text-slate-300 mb-2">ID</h3>
              <p className="text-slate-400 font-mono text-sm">{isComplaint ? item.complaint_id : item.scan_id}</p>
            </div>

            {isComplaint ? (
              <>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h3 className="text-xs text-slate-500 mb-1">Date</h3>
                    <p className="text-slate-300">{new Date(item.date).toLocaleDateString()}</p>
                  </div>
                  <div>
                    <h3 className="text-xs text-slate-500 mb-1">Status</h3>
                    <span className={`px-2 py-1 rounded-full text-xs font-semibold ${item.status === 'SUBMITTED' ? 'bg-amber-500/20 text-amber-400' : 'bg-emerald-500/20 text-emerald-400'}`}>
                      {item.status}
                    </span>
                  </div>
                  <div>
                    <h3 className="text-xs text-slate-500 mb-1">Shopkeeper</h3>
                    <p className="text-slate-300">{item.shopkeeper_name || 'N/A'}</p>
                  </div>
                  <div className="col-span-2">
                    <h3 className="text-xs text-slate-500 mb-1">Issue Description</h3>
                    <p className="text-slate-300 text-sm bg-slate-800 p-3 rounded-lg border border-slate-700">{item.description}</p>
                  </div>
                  {item.receipt_image_url && (
                    <div className="col-span-2 mt-4">
                      <div className="bg-slate-800 p-2 rounded-xl flex items-center justify-center">
                        <img src={`http://192.168.29.65:8080${item.receipt_image_url}`} alt="Evidence" className="max-h-64 rounded-xl object-contain border border-slate-700" />
                      </div>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <>
                {item.image_urls && Object.keys(item.image_urls).length > 0 && (
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700 mb-4">
                    <h3 className="text-sm font-semibold text-slate-300 mb-2">Scanned Evidence</h3>
                    <div className="flex overflow-x-auto space-x-4 pb-2">
                      {Object.entries(item.image_urls).map(([side, url]: any) => (
                        <div key={side} className="flex-shrink-0 w-32 relative group">
                          <img 
                            src={`http://192.168.29.65:8080${url}`} 
                            alt={side} 
                            className="h-24 w-24 rounded-lg object-cover border border-slate-600 hover:border-emerald-500 transition-colors cursor-pointer"
                            onClick={() => window.open(`http://192.168.29.65:8080${url}`, '_blank')}
                          />
                          <div className="absolute bottom-0 inset-x-0 bg-black/60 p-1 rounded-b-lg">
                            <p className="text-[10px] font-bold text-center text-white uppercase">{side}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Digital E-commerce Twin Section */}
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700 mb-4 flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-semibold text-slate-300">Digital E-commerce Twin</h3>
                    <p className="text-xs text-slate-500 mt-1">Cross-reference physical scan with online listings.</p>
                  </div>
                  <div className="flex space-x-2">
                    <button 
                      onClick={() => {
                        const brand = item.extracted_declarations?.manufacturer_name || '';
                        const product = item.extracted_declarations?.generic_product_name || item.product_category || '';
                        const query = encodeURIComponent(`${brand} ${product}`.trim() || 'Packaged Commodity');
                        window.open(`https://www.google.com/search?tbm=shop&q=${query}`, '_blank');
                      }}
                      className="flex items-center space-x-1 px-3 py-1.5 bg-blue-500/20 text-blue-400 hover:bg-blue-500/30 rounded-lg text-xs font-bold transition-colors"
                    >
                      <ShoppingCart className="w-3 h-3" />
                      <span>Google Shopping</span>
                    </button>
                    <button 
                      onClick={() => {
                        const brand = item.extracted_declarations?.manufacturer_name || '';
                        const product = item.extracted_declarations?.generic_product_name || item.product_category || '';
                        const query = encodeURIComponent(`${brand} ${product}`.trim() || 'Packaged Commodity');
                        window.open(`https://www.amazon.in/s?k=${query}`, '_blank');
                      }}
                      className="flex items-center space-x-1 px-3 py-1.5 bg-orange-500/20 text-orange-400 hover:bg-orange-500/30 rounded-lg text-xs font-bold transition-colors"
                    >
                      <Search className="w-3 h-3" />
                      <span>Amazon</span>
                    </button>
                  </div>
                </div>

                <div className="flex items-center space-x-6 p-4 bg-slate-800/50 rounded-xl border border-slate-700 mb-4">
                  <div 
                    className="relative w-16 h-16 flex items-center justify-center rounded-full bg-slate-900 border-4 shadow-lg" 
                    style={{ borderColor: item.status === 'PASS' ? '#10b981' : (item.compliance_summary?.compliance_score >= 60 ? '#f59e0b' : '#ef4444') }}
                  >
                    <span className="text-lg font-bold text-white">{item.compliance_summary?.compliance_score ?? 0}%</span>
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-slate-200 uppercase tracking-wide">Regulation Score</h3>
                    <p className="text-sm text-slate-400 mt-1">
                      {item.status === 'PASS' ? 'All mandatory Legal Metrology declarations detected.' : `Missing ${item.compliance_summary?.failed_rules ?? 'required'} declaration(s).`}
                    </p>
                  </div>
                </div>

                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                  <h3 className="text-sm font-semibold text-slate-300 mb-4">AI Legal Analysis</h3>
                  <div className="grid grid-cols-2 gap-4">
                    {item.evaluations?.map((e: any, idx: number) => (
                      <FlipCard key={idx} evaluation={e} />
                    ))}
                  </div>
                </div>

                <div className="bg-slate-800/50 rounded-xl border border-slate-700 mb-4 overflow-hidden shadow-lg shadow-cyan-500/5">
                  <div className="bg-cyan-900/30 px-4 py-3 border-b border-cyan-800/50 flex justify-between items-center">
                    <h3 className="text-sm font-bold text-cyan-400 uppercase tracking-wider">Product Category: {item.product_category || 'Unknown'}</h3>
                  </div>
                  <div className="divide-y divide-slate-700/50">
                    {Object.entries(item.extracted_declarations || {}).map(([key, val], idx) => (
                      <div key={idx} className={`flex px-4 py-3 ${idx % 2 === 0 ? 'bg-transparent' : 'bg-slate-800/30'}`}>
                        <div className="w-1/3 text-sm text-slate-400 font-medium capitalize">{key.replace(/_/g, ' ')}</div>
                        <div className={`w-2/3 text-sm text-right font-semibold ${val ? 'text-slate-200' : 'text-red-400'}`}>
                          {val !== null ? String(val) : 'NOT DETECTED'}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            )}
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
