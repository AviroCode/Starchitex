let authToken = 'mock-token-12345'
let onUnauthorized = () => {}

export function setToken(token) { authToken = token || 'mock-token-12345' }
export function setUnauthorizedHandler(fn) { onUnauthorized = fn }

export class ApiError extends Error {
  constructor(message, status) { super(message); this.status = status }
}

// Mock data
const MOCK_BRANCHES = [
  { branchId: 1, name: 'Aurora Hotel Bangkok', city: 'Bangkok', address: '123 Sukhumvit Rd' },
  { branchId: 2, name: 'Aurora Hotel Chiang Mai', city: 'Chiang Mai', address: '88 Nimmanhaemin Rd' },
  { branchId: 3, name: 'Aurora Hotel Phuket', city: 'Phuket', address: '55 Patong Beach Rd' },
]

const MOCK_ROOMS = [
  { roomId: 1, roomNumber: '101', floor: 1, roomTypeId: 1, branchId: 1 },
  { roomId: 2, roomNumber: '102', floor: 1, roomTypeId: 2, branchId: 1 },
  { roomId: 3, roomNumber: '201', floor: 2, roomTypeId: 3, branchId: 1 },
  { roomId: 4, roomNumber: '202', floor: 2, roomTypeId: 4, branchId: 1 },
  { roomId: 5, roomNumber: '301', floor: 3, roomTypeId: 5, branchId: 1 },
  { roomId: 6, roomNumber: '302', floor: 3, roomTypeId: 6, branchId: 1 },
  { roomId: 7, roomNumber: '401', floor: 4, roomTypeId: 7, branchId: 1 },
  { roomId: 8, roomNumber: '402', floor: 4, roomTypeId: 8, branchId: 1 },
]

const MOCK_ROOM_TYPES = [
  { roomTypeId: 1, typeName: 'Single', capacity: 1, basePrice: 1500 },
  { roomTypeId: 2, typeName: 'Double', capacity: 2, basePrice: 2000 },
  { roomTypeId: 3, typeName: 'Twin', capacity: 2, basePrice: 2200 },
  { roomTypeId: 4, typeName: 'Queen', capacity: 2, basePrice: 2500 },
  { roomTypeId: 5, typeName: 'King', capacity: 2, basePrice: 3500 },
  { roomTypeId: 6, typeName: 'Suite', capacity: 4, basePrice: 5500 },
  { roomTypeId: 7, typeName: 'Family Suite', capacity: 6, basePrice: 6500 },
  { roomTypeId: 8, typeName: 'Penthouse', capacity: 8, basePrice: 8500 },
]

const MOCK_GUESTS = [
  { guestId: 1, firstName: 'John', lastName: 'Doe', email: 'john@example.com', nationality: 'American', phoneNumber: '+1-555-0199' },
  { guestId: 2, firstName: 'Jane', lastName: 'Smith', email: 'jane@example.com', nationality: 'British', phoneNumber: '+44-20-7946-0192' },
  { guestId: 3, firstName: 'Yuki', lastName: 'Tanaka', email: 'yuki@example.com', nationality: 'Japanese', phoneNumber: '+81-90-1234-5678' },
  { guestId: 4, firstName: 'David', lastName: 'Wilson', email: 'david@example.com', nationality: 'Australian', phoneNumber: '+61-2-9876-5432' },
  { guestId: 5, firstName: 'Maria', lastName: 'Garcia', email: 'maria@example.com', nationality: 'Spanish', phoneNumber: '+34-91-123-4567' },
]

const MOCK_RESERVATIONS = [
  { reservationId: 1, guestId: 1, checkInDate: '2026-07-10', checkOutDate: '2026-07-13', numOfGuests: 2, status: 'Confirmed' },
  { reservationId: 2, guestId: 2, checkInDate: '2026-07-12', checkOutDate: '2026-07-15', numOfGuests: 1, status: 'Pending' },
  { reservationId: 3, guestId: 3, checkInDate: '2026-07-15', checkOutDate: '2026-07-18', numOfGuests: 3, status: 'Checked In' },
  { reservationId: 4, guestId: 4, checkInDate: '2026-07-20', checkOutDate: '2026-07-22', numOfGuests: 2, status: 'Pending' },
  { reservationId: 5, guestId: 5, checkInDate: '2026-07-25', checkOutDate: '2026-07-28', numOfGuests: 4, status: 'Confirmed' },
]

const MOCK_INVOICES = [
  { invoiceId: 1, reservationId: 1, payerGuestId: 1, subTotal: 4500, taxAmount: 315, discount: 0, totalAmount: 4815, status: 'Paid' },
  { invoiceId: 2, reservationId: 2, payerGuestId: 2, subTotal: 2000, taxAmount: 140, discount: 0, totalAmount: 2140, status: 'Pending' },
  { invoiceId: 3, reservationId: 3, payerGuestId: 3, subTotal: 6600, taxAmount: 462, discount: 200, totalAmount: 6862, status: 'Partially Paid' },
  { invoiceId: 4, reservationId: 4, payerGuestId: 4, subTotal: 4000, taxAmount: 280, discount: 0, totalAmount: 4280, status: 'Pending' },
]

const MOCK_PAYMENTS = [
  { paymentId: 1, invoiceId: 1, amount: 4815, paymentMethod: 'Credit Card', transactionRef: 'TXN-001' },
  { paymentId: 2, invoiceId: 3, amount: 3000, paymentMethod: 'Cash', transactionRef: 'TXN-002' },
]

// Mock request handler
async function request(path, options = {}) {
  console.log('Mock API call:', path, options)
  
  // Simulate network delay
  await new Promise(resolve => setTimeout(resolve, 300))
  
  // Return mock data based on the path
  if (path.includes('/branches')) {
    return MOCK_BRANCHES
  }
  
  if (path.includes('/rooms?branchId')) {
    // Filter rooms by branch
    const branchId = parseInt(path.split('branchId=')[1])
    return MOCK_ROOMS.filter(r => r.branchId === branchId)
  }
  
  if (path.includes('/rooms')) {
    return MOCK_ROOMS
  }
  
  if (path.includes('/room-types')) {
    return MOCK_ROOM_TYPES
  }
  
  if (path.includes('/guests')) {
    if (options.method === 'POST') {
      const newGuest = JSON.parse(options.body)
      const guest = { ...newGuest, guestId: MOCK_GUESTS.length + 1 }
      MOCK_GUESTS.push(guest)
      return guest
    }
    return MOCK_GUESTS
  }
  
  if (path.includes('/reservations')) {
    if (options.method === 'POST') {
      const newRes = JSON.parse(options.body)
      const reservation = { ...newRes, reservationId: MOCK_RESERVATIONS.length + 1 }
      MOCK_RESERVATIONS.push(reservation)
      return reservation
    }
    if (options.method === 'PUT') {
      // Extract ID from path
      const id = parseInt(path.split('/').pop())
      const updated = JSON.parse(options.body)
      const index = MOCK_RESERVATIONS.findIndex(r => r.reservationId === id)
      if (index !== -1) {
        MOCK_RESERVATIONS[index] = { ...MOCK_RESERVATIONS[index], ...updated }
        return MOCK_RESERVATIONS[index]
      }
      return { success: true }
    }
    return MOCK_RESERVATIONS
  }
  
  if (path.includes('/invoices')) {
    return MOCK_INVOICES
  }
  
  if (path.includes('/payments')) {
    return MOCK_PAYMENTS
  }
  
  console.warn('Unknown API endpoint:', path)
  return []
}

export const api = {
  async login(username, password) {
    console.log('Mock login:', username, password)
    // Check if user exists in mock data
    const user = MOCK_GUESTS.find(g => g.email === username) || 
                 { username, firstName: 'Test', lastName: 'User' }
    return 'mock-token-12345'
  },

  branches: () => request('/branches'),
  guests: () => request('/guests'),
  createGuest: (g) => request('/guests', { method: 'POST', body: JSON.stringify(g) }),

  roomsByBranch: (branchId) => request(`/rooms?branchId=${branchId}`),
  roomTypes: () => request('/room-types'),
  availabilityByRoom: (roomId) => request(`/room-availability?roomId=${roomId}`),

  reservations: () => request('/reservations'),
  createReservation: (r) => request('/reservations', { method: 'POST', body: JSON.stringify(r) }),
  updateReservation: (id, r) => request(`/reservations/${id}`, { method: 'PUT', body: JSON.stringify(r) }),

  invoices: () => request('/invoices'),
  paymentsByInvoice: (invoiceId) => request(`/payments/invoice/${invoiceId}`),
}
