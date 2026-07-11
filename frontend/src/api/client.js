// Single fetch wrapper for the whole app (FRONTEND_GUIDE.md §1–2, §4).
// - relative /api paths (Vite proxy handles origin)
// - Bearer token on every call
// - normalises the backend's bare-500 constraint errors into a friendly message

let authToken = null
let onUnauthorized = () => {}

export function setToken(token) { authToken = token }
export function setUnauthorizedHandler(fn) { onUnauthorized = fn }

export class ApiError extends Error {
  constructor(message, status) { super(message); this.status = status }
}

async function request(path, options = {}) {
  const res = await fetch(path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
      ...(options.headers || {}),
    },
  })
  if (res.status === 401) {
    onUnauthorized()
    throw new ApiError('Session expired — please sign in again.', res.status)
  }
  if (res.status === 403) {
    // Authorization (not authentication) failure — this user lacks permission
    // for this endpoint. Do NOT log out; surface an empty/error result instead.
    throw new ApiError('Not permitted for this account.', 403)
  }
  if (!res.ok) {
    // Constraint violations arrive as a bare 500 with no useful body (§4) —
    // the caller supplies the human explanation.
    throw new ApiError(`Request failed (${res.status})`, res.status)
  }
  const ct = res.headers.get('content-type') || ''
  return ct.includes('json') ? res.json() : res.text()
}

export const api = {
  // auth (§2): returns the raw JWT string
  async login(username, password) {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    })
    if (!res.ok) throw new ApiError(res.status === 401 ? 'Wrong username or password.' : `Login failed (${res.status})`, res.status)
    const text = await res.text()
    const jwt = text.replace(/^"|"$/g, '').trim()
    if (!jwt) throw new ApiError('Empty token from server.', 500)
    return jwt
  },

  branches: () => request('/api/branches'),
  guests: () => request('/api/guests'),
  createGuest: (g) => request('/api/guests', { method: 'POST', body: JSON.stringify(g) }),

  roomsByBranch: (branchId) => request(`/api/rooms/branch/${branchId}`),
  roomTypes: () => request('/api/room-types'),                       // kebab-case (§3)
  availabilityByRoom: (roomId) => request(`/api/room-availabilities/room/${roomId}`),

  reservations: () => request('/api/reservations'),
  createReservation: (r) => request('/api/reservations', { method: 'POST', body: JSON.stringify(r) }),
  updateReservation: (id, r) => request(`/api/reservations/${id}`, { method: 'PUT', body: JSON.stringify(r) }),

  invoices: () => request('/api/invoices'),
  paymentsByInvoice: (invoiceId) => request(`/api/payments/invoice/${invoiceId}`),
}
