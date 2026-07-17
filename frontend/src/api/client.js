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
  if (res.status === 401 || res.status === 403) {
    onUnauthorized()
    throw new ApiError('Session expired — please sign in again.', res.status)
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
  createBranch: (b) => request('/api/branches', { method: 'POST', body: JSON.stringify(b) }),
  updateBranch: (id, b) => request(`/api/branches/${id}`, { method: 'PUT', body: JSON.stringify(b) }),

  guests: () => request('/api/guests'),
  guestById: (id) => request(`/api/guests/${id}`),
  createGuest: (g) => request('/api/guests', { method: 'POST', body: JSON.stringify(g) }),
  updateGuest: (id, g) => request(`/api/guests/${id}`, { method: 'PUT', body: JSON.stringify(g) }),

  roomsByBranch: (branchId) => request(`/api/rooms/branch/${branchId}`),
  roomTypes: () => request('/api/room-types'),                       // kebab-case (§3)
  createRoomType: (rt) => request('/api/room-types', { method: 'POST', body: JSON.stringify(rt) }),
  updateRoomType: (id, rt) => request(`/api/room-types/${id}`, { method: 'PUT', body: JSON.stringify(rt) }),
  availabilityByRoom: (roomId) => request(`/api/room-availabilities/room/${roomId}`),

  services: () => request('/api/services'),
  createService: (s) => request('/api/services', { method: 'POST', body: JSON.stringify(s) }),
  updateService: (id, s) => request(`/api/services/${id}`, { method: 'PUT', body: JSON.stringify(s) }),

  reservations: () => request('/api/reservations'),
  reservationsByGuest: (guestId) => request(`/api/reservations/guest/${guestId}`),
  createReservation: (r) => request('/api/reservations', { method: 'POST', body: JSON.stringify(r) }),
  updateReservation: (id, r) => request(`/api/reservations/${id}`, { method: 'PUT', body: JSON.stringify(r) }),
  confirmReservation: (id) => request(`/api/reservations/${id}/confirm`, { method: 'POST' }),
  checkInReservation: (id) => request(`/api/reservations/${id}/check-in`, { method: 'POST' }),
  checkOutReservation: (id) => request(`/api/reservations/${id}/check-out`, { method: 'POST' }),
  cancelReservation: (id) => request(`/api/reservations/${id}/cancel`, { method: 'POST' }),

  roomsForReservation: (reservationId) => request(`/api/reservation-rooms/reservation/${reservationId}`),
  assignRoomToReservation: (reservationId, roomId) =>
    request('/api/reservation-rooms', { method: 'POST', body: JSON.stringify({ reservationId, roomId }) }),

  invoices: () => request('/api/invoices'),
  invoicesByGuest: (guestId) => request(`/api/invoices/guest/${guestId}`),
  paymentsByInvoice: (invoiceId) => request(`/api/payments/invoice/${invoiceId}`),

  roles: () => request('/api/roles'),
  permissions: () => request('/api/permissions'),
  rolePermissionsForRole: (roleId) => request(`/api/role-permissions/role/${roleId}`),
  assignPermission: (roleId, permissionId) =>
    request('/api/role-permissions', { method: 'POST', body: JSON.stringify({ roleId, permissionId }) }),
  revokePermission: (roleId, permissionId) =>
    request(`/api/role-permissions/role/${roleId}/permission/${permissionId}`, { method: 'DELETE' }),

  employees: () => request('/api/employees'),
  employeesByBranch: (branchId) => request(`/api/employees/branch/${branchId}`),
  createEmployee: (e) => request('/api/employees', { method: 'POST', body: JSON.stringify(e) }),
  updateEmployee: (id, e) => request(`/api/employees/${id}`, { method: 'PUT', body: JSON.stringify(e) }),
  createEmployeeCredentials: (c) => request('/api/employee-credentials', { method: 'POST', body: JSON.stringify(c) }),

  roomTasks: () => request('/api/room-tasks'),
  roomTasksByRoom: (roomId) => request(`/api/room-tasks/room/${roomId}`),
  createRoomTask: (t) => request('/api/room-tasks', { method: 'POST', body: JSON.stringify(t) }),
  updateRoomTask: (id, t) => request(`/api/room-tasks/${id}`, { method: 'PUT', body: JSON.stringify(t) }),

  roomMaintenances: () => request('/api/room-maintenances'),
  roomMaintenancesByRoom: (roomId) => request(`/api/room-maintenances/room/${roomId}`),
  createRoomMaintenance: (m) => request('/api/room-maintenances', { method: 'POST', body: JSON.stringify(m) }),
  updateRoomMaintenance: (id, m) => request(`/api/room-maintenances/${id}`, { method: 'PUT', body: JSON.stringify(m) }),

  facilitiesByBranch: (branchId) => request(`/api/facilities/branch/${branchId}`),
  createFacility: (f) => request('/api/facilities', { method: 'POST', body: JSON.stringify(f) }),
  updateFacility: (id, f) => request(`/api/facilities/${id}`, { method: 'PUT', body: JSON.stringify(f) }),
  facilityBookingsByReservation: (reservationId) => request(`/api/facility-bookings/reservation/${reservationId}`),
  createFacilityBooking: (b) => request('/api/facility-bookings', { method: 'POST', body: JSON.stringify(b) }),

  serviceRequests: () => request('/api/service-requests'),
  serviceRequestsByReservation: (reservationId) => request(`/api/service-requests/reservation/${reservationId}`),
  createServiceRequest: (r) => request('/api/service-requests', { method: 'POST', body: JSON.stringify(r) }),
  updateServiceRequest: (id, r) => request(`/api/service-requests/${id}`, { method: 'PUT', body: JSON.stringify(r) }),

  auditLogs: () => request('/api/audit-logs'),
  auditLogsByEmployee: (employeeId) => request(`/api/audit-logs/employee/${employeeId}`),
  auditLogsByTable: (tableName) => request(`/api/audit-logs/table/${tableName}`),
}
