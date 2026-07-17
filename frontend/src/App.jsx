import { useEffect, useMemo, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext.jsx'
import { api } from './api/client.js'
import { decodeJwt } from './lib/jwt.js'
import Sidebar from './components/Sidebar.jsx'
import LoginPage from './pages/LoginPage.jsx'
import RegisterPage from './pages/RegisterPage.jsx'
import Banner from './components/Banner.jsx'

import RoomsPage from './pages/RoomsPage.jsx'
import ReservationsPage from './pages/ReservationsPage.jsx'
import GuestsPage from './pages/GuestsPage.jsx'
import BillingPage from './pages/BillingPage.jsx'

import HousekeepingPage from './pages/staff/HousekeepingPage.jsx'
import ServiceRequestsPage from './pages/staff/ServiceRequestsPage.jsx'
import FacilitiesPage from './pages/staff/FacilitiesPage.jsx'

import BookRoomPage from './pages/guest/BookRoomPage.jsx'
import MyReservationsPage from './pages/guest/MyReservationsPage.jsx'
import MyInvoicesPage from './pages/guest/MyInvoicesPage.jsx'
import MyProfilePage from './pages/guest/MyProfilePage.jsx'

import BranchesPage from './pages/admin/BranchesPage.jsx'
import EmployeesPage from './pages/admin/EmployeesPage.jsx'
import CatalogPage from './pages/admin/CatalogPage.jsx'
import RolesPermissionsPage from './pages/admin/RolesPermissionsPage.jsx'
import AuditLogPage from './pages/admin/AuditLogPage.jsx'
import AnalyticsPage from './pages/admin/AnalyticsPage.jsx'

const ADMIN_TIER_ROLES = ['System Administrator', 'Hotel Owner', 'Sales Executive']
const GUEST_HOME = '/guest/book'
const STAFF_HOME = '/staff/rooms'

function LoginRoute() {
  const { token } = useAuth()
  if (token) return <Navigate to="/" replace />
  return <LoginPage />
}

function RegisterRoute() {
  const { token } = useAuth()
  if (token) return <Navigate to="/" replace />
  return <RegisterPage />
}

function Shell() {
  const { token } = useAuth()
  const location = useLocation()
  const claims = useMemo(() => (token ? decodeJwt(token) : null), [token])
  const isGuest = !!claims?.guestId

  const [branches, setBranches] = useState([])
  const [branchId, setBranchId] = useState(null)
  const [guests, setGuests] = useState([])
  const [roles, setRoles] = useState([])
  const [ready, setReady] = useState(false)
  const [bootError, setBootError] = useState(null)

  const roleName = useMemo(() => {
    if (!claims) return null
    return roles.find((r) => r.roleId === claims.roleId)?.roleName ?? null
  }, [claims, roles])
  const isAdminTier = ADMIN_TIER_ROLES.includes(roleName)

  const refreshGuests = () => api.guests().then(setGuests).catch(() => {})
  const refreshBranches = () => api.branches().then(setBranches).catch(() => {})

  useEffect(() => {
    if (!token || !claims) return
    ;(async () => {
      try {
        const b = await api.branches()
        setBranches(b)
        if (b.length) setBranchId(b[0].branchId)
        const r = await api.roles()
        setRoles(r)
        // Only staff/admin can list every guest — a Guest login gets a 403
        // on this endpoint, so it's skipped entirely for guest sessions.
        if (claims.guestId == null) {
          const g = await api.guests()
          setGuests(g)
        }
        setReady(true)
      } catch (e) {
        setBootError(`Could not load data — is the backend running with the Vite proxy target on :8080? (${e.message})`)
      }
    })()
  }, [token])

  if (!token) return <Navigate to="/login" replace />
  if (!ready) {
    return bootError ? (
      <div className="login-wrap"><Banner kind="error">{bootError}</Banner></div>
    ) : null
  }

  // Route guards: a guest session can only ever be in /guest/*; a staff/admin
  // session can only ever be in /staff/* or /admin/* (and /admin/* further
  // requires an admin-tier role).
  const inGuestArea = location.pathname.startsWith('/guest')
  const inAdminArea = location.pathname.startsWith('/admin')
  if (isGuest && !inGuestArea) return <Navigate to={GUEST_HOME} replace />
  if (!isGuest && inGuestArea) return <Navigate to={STAFF_HOME} replace />
  if (inAdminArea && !isAdminTier) return <Navigate to={STAFF_HOME} replace />

  const navSections = isGuest
    ? [{
        label: null,
        items: [
          { path: '/guest/book', label: 'Book a Room' },
          { path: '/guest/reservations', label: 'My Reservations' },
          { path: '/guest/invoices', label: 'My Invoices' },
          { path: '/guest/profile', label: 'My Profile' },
        ],
      }]
    : [
        {
          label: null,
          items: [
            { path: '/staff/rooms', label: 'Rooms' },
            { path: '/staff/reservations', label: 'Reservations' },
            { path: '/staff/guests', label: 'Guests' },
            { path: '/staff/billing', label: 'Billing' },
            { path: '/staff/housekeeping', label: 'Housekeeping' },
            { path: '/staff/service-requests', label: 'Service Requests' },
            { path: '/staff/facilities', label: 'Facilities' },
          ],
        },
        ...(isAdminTier
          ? [{
              label: 'Admin',
              items: [
                { path: '/admin/branches', label: 'Branches' },
                { path: '/admin/employees', label: 'Employees' },
                { path: '/admin/catalog', label: 'Catalog' },
                { path: '/admin/roles', label: 'Roles & Permissions' },
                { path: '/admin/audit', label: 'Audit Log' },
                { path: '/admin/analytics', label: 'Analytics' },
              ],
            }]
          : []),
      ]

  const tagline = isGuest ? 'Guest Portal' : isAdminTier ? 'Front Desk Console · Admin' : 'Front Desk Console'

  return (
    <div className="shell">
      <Sidebar tagline={tagline} navSections={navSections} />
      <main className="content">
        <Routes>
          <Route path="/" element={<Navigate to={isGuest ? GUEST_HOME : STAFF_HOME} replace />} />

          <Route path="/guest/book" element={<BookRoomPage branches={branches} guestId={claims?.guestId} />} />
          <Route path="/guest/reservations" element={<MyReservationsPage guestId={claims?.guestId} />} />
          <Route path="/guest/invoices" element={<MyInvoicesPage guestId={claims?.guestId} />} />
          <Route path="/guest/profile" element={<MyProfilePage guestId={claims?.guestId} />} />

          <Route path="/staff/rooms" element={<RoomsPage branches={branches} branchId={branchId} setBranchId={setBranchId} />} />
          <Route path="/staff/reservations" element={<ReservationsPage guests={guests} branchId={branchId} />} />
          <Route path="/staff/guests" element={<GuestsPage guests={guests} refreshGuests={refreshGuests} />} />
          <Route path="/staff/billing" element={<BillingPage guests={guests} />} />
          <Route path="/staff/housekeeping" element={<HousekeepingPage branches={branches} branchId={branchId} setBranchId={setBranchId} />} />
          <Route path="/staff/service-requests" element={<ServiceRequestsPage />} />
          <Route path="/staff/facilities" element={<FacilitiesPage branches={branches} branchId={branchId} setBranchId={setBranchId} />} />

          <Route path="/admin/branches" element={<BranchesPage branches={branches} refreshBranches={refreshBranches} roleName={roleName} />} />
          <Route path="/admin/employees" element={<EmployeesPage branches={branches} roleName={roleName} />} />
          <Route path="/admin/catalog" element={<CatalogPage branches={branches} />} />
          <Route path="/admin/roles" element={<RolesPermissionsPage roleName={roleName} />} />
          <Route path="/admin/audit" element={<AuditLogPage />} />
          <Route path="/admin/analytics" element={<AnalyticsPage />} />

          <Route path="*" element={<Navigate to={isGuest ? GUEST_HOME : STAFF_HOME} replace />} />
        </Routes>
      </main>
    </div>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginRoute />} />
          <Route path="/register" element={<RegisterRoute />} />
          <Route path="/*" element={<Shell />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
