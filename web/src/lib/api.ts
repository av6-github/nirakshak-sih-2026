import axios from 'axios';

const API_URL = 'http://192.168.29.65:8080';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const fetchReviewQueue = async () => {
  const response = await api.get('/reviews/queue');
  return response.data;
};

export const fetchComplaintsQueue = async () => {
  const response = await api.get('/complaints');
  return response.data;
};

export const submitScanReview = async (scanId: string, officerId: string, decision: string) => {
  const response = await api.post('/reviews', {
    scan_id: scanId,
    reviewer_id: officerId,
    decision,
    notes: 'Officer reviewed from web dashboard',
  });
  return response.data;
};

export const submitComplaintReview = async (complaintId: string, officerId: string, status: string) => {
  const response = await api.patch(`/complaints/${complaintId}/review`, {
    officer_id: officerId,
    status,
    resolution_notes: 'Officer reviewed from web dashboard',
  });
  return response.data;
};

export const fetchManufacturerHistory = async (name: string) => {
  const response = await api.get(`/manufacturers/${name}/history`);
  return response.data;
};

export const searchProducts = async (query: string) => {
  const response = await api.get(`/products/search?query=${encodeURIComponent(query)}`);
  return response.data;
};

export const fetchProductHistory = async (productId: string) => {
  const response = await api.get(`/products/${productId}`);
  return response.data;
};

export const chatWithRAG = async (query: string) => {
  const response = await api.post('/chat', { query });
  return response.data;
};

export const fetchManufacturerRatings = async () => {
  const response = await api.get('/manufacturers/ratings');
  return response.data;
};

export const rateManufacturer = async (name: string, officerId: string, rating: string, notes?: string) => {
  const response = await api.post(`/manufacturers/${encodeURIComponent(name)}/rate`, {
    officer_id: officerId,
    rating,
    notes,
  });
  return response.data;
};
