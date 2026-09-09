'use client';

import React, { useState, useRef, useEffect } from 'react';
import { ChatMessage } from '../types';
import { OfficerApi } from '../services/api';
import { 
  Bot, 
  Send, 
  Sparkles, 
  BookOpen, 
  User, 
  Scale
} from 'lucide-react';

export const LegalChatTab: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 'welcome',
      sender: 'assistant',
      text: `Greetings, Officer Raj. I am **Nirikshak AI Legal Counsel**, your statutory intelligence assistant grounded in the **Legal Metrology Act, 2009** and the **Legal Metrology (Packaged Commodities) Rules, 2011 (LMPC Rules)**.\n\nYou can query statutory provisions, compounding penalty calculations under Section 36/48, evidence standards, or specific packaging rules (such as Rule 6 mandatory declarations and Rule 18(2) dual MRP enforcement).`,
      citations: [
        {
          citation_id: '[1]',
          document: 'Legal Metrology (Packaged Commodities) Rules, 2011',
          rule: 'Statutory Overview',
          excerpt: 'Official codified standards for pre-packaged commodities, labeling standards, font sizes, and price surveillance.',
        }
      ],
      suggested_followups: [
        'What are the mandatory font sizes for Net Quantity under Schedule II?',
        'What is the compounding penalty for MRP overcharging under Rule 18(2)?',
        'Can an officer seize non-compliant commodities under Section 15?',
        'What are the 7 mandatory declarations required on packages under Rule 6(1)?',
      ],
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
  ]);

  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  const handleSend = async (queryText?: string) => {
    const textToSend = queryText || input;
    if (!textToSend.trim() || isLoading) return;

    const userMsg: ChatMessage = {
      id: `usr-${Date.now()}`,
      sender: 'user',
      text: textToSend,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsLoading(true);

    try {
      const res = await OfficerApi.sendChatMessage(textToSend);
      const botMsg: ChatMessage = {
        id: `bot-${Date.now()}`,
        sender: 'assistant',
        text: res.reply,
        citations: res.citations,
        suggested_followups: res.suggested_followups,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, botMsg]);
    } catch {
      const fallbackMsg: ChatMessage = {
        id: `bot-${Date.now()}`,
        sender: 'assistant',
        text: 'An error occurred while retrieving statutory context from the knowledge base. Please try again.',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, fallbackMsg]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="tab-wrapper animate-fade-in">
      <div className="chat-container glass-panel">
        {/* Chat Header */}
        <div className="chat-header">
          <div className="header-left">
            <div className="bot-avatar">
              <Bot size={22} />
            </div>
            <div>
              <div className="bot-title-row">
                <h3 className="bot-title">Nirikshak AI Statutory Legal Counsel</h3>
                <span className="badge badge-emerald">RAG KNOWLEDGEBASE CONNECTED</span>
              </div>
              <span className="bot-subtitle">
                Legal Metrology Act 2009 • Packaged Commodities Rules 2011 • Section 36/48 Sanctions
              </span>
            </div>
          </div>
        </div>

        {/* Message Stream */}
        <div className="message-stream">
          {messages.map((m) => {
            const isUser = m.sender === 'user';

            return (
              <div key={m.id} className={`message-row ${isUser ? 'user-row' : 'bot-row'}`}>
                {!isUser && (
                  <div className="msg-avatar bot-av">
                    <Scale size={16} />
                  </div>
                )}

                <div className={`message-bubble ${isUser ? 'user-bubble' : 'bot-bubble'}`}>
                  <div className="msg-content">
                    {m.text.split('\n').map((line, idx) => {
                      if (!line.trim()) return <br key={idx} />;
                      return (
                        <p key={idx} className="msg-line">
                          {line}
                        </p>
                      );
                    })}
                  </div>

                  {/* Citations Box */}
                  {m.citations && m.citations.length > 0 && (
                    <div className="citations-box">
                      <div className="citations-header">
                        <BookOpen size={13} className="text-emerald" />
                        <span>Statutory Citations & Legal Chunks:</span>
                      </div>
                      <div className="citations-list">
                        {m.citations.map((c, ci) => (
                          <div key={ci} className="citation-pill">
                            <span className="citation-num font-mono">{c.citation_id}</span>
                            <div className="citation-info">
                              <span className="citation-rule">{c.rule}</span>
                              <span className="citation-doc"> ({c.document})</span>
                              <p className="citation-excerpt">&quot;{c.excerpt}&quot;</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Suggested Followups */}
                  {m.suggested_followups && m.suggested_followups.length > 0 && (
                    <div className="followups-box">
                      <span className="followups-title">Recommended Legal Queries:</span>
                      <div className="followups-pills">
                        {m.suggested_followups.map((f, fi) => (
                          <button
                            key={fi}
                            onClick={() => handleSend(f)}
                            className="followup-btn"
                          >
                            <Sparkles size={12} className="text-emerald" />
                            <span>{f}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                  <span className="msg-timestamp font-mono">{m.timestamp}</span>
                </div>

                {isUser && (
                  <div className="msg-avatar user-av">
                    <User size={16} />
                  </div>
                )}
              </div>
            );
          })}

          {isLoading && (
            <div className="message-row bot-row animate-fade-in">
              <div className="msg-avatar bot-av">
                <Scale size={16} />
              </div>
              <div className="message-bubble bot-bubble loading-bubble">
                <div className="typing-dots">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
                <span className="loading-text font-mono">
                  Searching Legal Metrology Act & Rules Vector Embeddings...
                </span>
              </div>
            </div>
          )}

          <div ref={chatEndRef} />
        </div>

        {/* Input Bar */}
        <div className="chat-input-bar">
          <input
            type="text"
            placeholder="Ask anything on LMPC Rules 2011, packaging violations, font standards, or Section 36 penalties..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSend();
            }}
            disabled={isLoading}
            className="chat-input"
          />
          <button
            onClick={() => handleSend()}
            disabled={isLoading || !input.trim()}
            className="btn-primary send-btn"
          >
            <Send size={15} />
            <span>Send Query</span>
          </button>
        </div>
      </div>

      <style jsx>{`
        .tab-wrapper {
          height: calc(100vh - 150px);
          display: flex;
          flex-direction: column;
        }

        .chat-container {
          flex: 1;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .chat-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 14px 20px;
          border-bottom: 1px solid #e2e8f0;
          background: rgba(255, 255, 255, 0.85);
        }

        .header-left {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .bot-avatar {
          width: 40px;
          height: 40px;
          border-radius: 12px;
          background: #0f172a;
          color: #ffffff;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 12px rgba(15, 23, 42, 0.15);
        }

        .bot-title-row {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .bot-title {
          font-size: 1rem;
          font-weight: 800;
          color: #0f172a;
        }

        .bot-subtitle {
          font-size: 0.72rem;
          color: #64748b;
          margin-top: 2px;
          display: block;
          font-weight: 500;
        }

        .message-stream {
          flex: 1;
          overflow-y: auto;
          padding: 20px;
          display: flex;
          flex-direction: column;
          gap: 18px;
        }

        .message-row {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          max-width: 82%;
        }

        .bot-row {
          align-self: flex-start;
        }

        .user-row {
          align-self: flex-end;
          flex-direction: row;
        }

        .msg-avatar {
          width: 32px;
          height: 32px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .bot-av {
          background: #d1fae5;
          color: #059669;
          border: 1px solid #a7f3d0;
        }

        .user-av {
          background: #e0f2fe;
          color: #0284c7;
          border: 1px solid #bae6fd;
        }

        .message-bubble {
          padding: 14px 18px;
          border-radius: 14px;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .bot-bubble {
          background: rgba(255, 255, 255, 0.95);
          border: 1px solid #e2e8f0;
          color: #0f172a;
          box-shadow: 0 4px 16px rgba(15, 23, 42, 0.04);
        }

        .user-bubble {
          background: #0f172a;
          border: 1px solid #0f172a;
          color: #ffffff;
          box-shadow: 0 4px 16px rgba(15, 23, 42, 0.15);
        }

        .msg-line {
          font-size: 0.88rem;
          line-height: 1.5;
        }

        .citations-box {
          margin-top: 6px;
          background: #f8fafc;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 10px;
        }

        .citations-header {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 0.72rem;
          font-weight: 700;
          color: #475569;
          margin-bottom: 6px;
        }

        .text-emerald {
          color: #059669;
        }

        .citations-list {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .citation-pill {
          display: flex;
          align-items: flex-start;
          gap: 8px;
          font-size: 0.75rem;
          background: #ffffff;
          border: 1px solid #e2e8f0;
          padding: 6px 8px;
          border-radius: 6px;
        }

        .citation-num {
          font-weight: 800;
          color: #059669;
        }

        .citation-rule {
          font-weight: 700;
          color: #0f172a;
        }

        .citation-doc {
          color: #64748b;
        }

        .citation-excerpt {
          font-style: italic;
          color: #475569;
          margin-top: 2px;
          font-size: 0.72rem;
        }

        .followups-box {
          margin-top: 6px;
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .followups-title {
          font-size: 0.7rem;
          font-weight: 800;
          color: #64748b;
          text-transform: uppercase;
        }

        .followups-pills {
          display: flex;
          flex-wrap: wrap;
          gap: 6px;
        }

        .followup-btn {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          background: #ecfdf5;
          border: 1px solid #a7f3d0;
          color: #065f46;
          font-size: 0.75rem;
          font-weight: 600;
          font-family: var(--font-outfit);
          padding: 5px 10px;
          border-radius: 9999px;
          cursor: pointer;
          transition: all 0.2s;
        }

        .followup-btn:hover {
          background: #d1fae5;
          border-color: #10b981;
        }

        .msg-timestamp {
          align-self: flex-end;
          font-size: 0.65rem;
          color: #94a3b8;
          margin-top: 2px;
        }

        .loading-bubble {
          display: flex;
          flex-direction: row;
          align-items: center;
          gap: 12px;
        }

        .typing-dots {
          display: flex;
          gap: 4px;
        }

        .typing-dots span {
          width: 6px;
          height: 6px;
          background: #10b981;
          border-radius: 50%;
          animation: bounce 1.4s infinite ease-in-out both;
        }

        .typing-dots span:nth-child(1) {
          animation-delay: -0.32s;
        }
        .typing-dots span:nth-child(2) {
          animation-delay: -0.16s;
        }

        @keyframes bounce {
          0%, 80%, 100% {
            transform: scale(0);
          }
          40% {
            transform: scale(1);
          }
        }

        .loading-text {
          font-size: 0.75rem;
          color: #64748b;
        }

        .chat-input-bar {
          padding: 14px 20px;
          border-top: 1px solid #e2e8f0;
          background: rgba(255, 255, 255, 0.85);
          display: flex;
          gap: 12px;
        }

        .chat-input {
          flex: 1;
          background: #ffffff;
          border: 1px solid #cbd5e1;
          border-radius: 12px;
          padding: 12px 16px;
          color: #0f172a;
          font-size: 0.88rem;
          font-family: var(--font-outfit);
          outline: none;
        }

        .chat-input:focus {
          border-color: #10b981;
          box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.15);
        }

        .send-btn {
          padding: 10px 20px;
        }
      `}</style>
    </div>
  );
};
