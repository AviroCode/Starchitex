import { useEffect, useState } from 'react'
import { AuthProvider, useAuth } from './context/AuthContext.jsx'
import { api } from './api/client.js'
import Sidebar from './components/Sidebar.jsx'
import LoginPage from './pages/LoginPage.jsx'
import RoomsPage from './pages/RoomsPage.jsx'
import ReservationsPage from './pages/ReservationsPage.jsx'
import GuestsPage from './pages/GuestsPage.jsx'
import BillingPage from './pages/BillingPage.jsx'
import Banner from './components/Banner.jsx'

function Shell() {
  const { token } = useAuth()
  const [page, setPage] = useState('rooms')
  const [branches, setBranches] = useState([])
  const [branchId, setBranchId] = useState(null)
  const [guests, setGuests] = useState([])
  const [bootError, setBootError] = useState(null)

  const refreshGuests = () => api.guests().then(setGuests).catch(() => {})

  useEffect(() => {
    if (!token) return
    ;(async () => {
      try {
        const [b, g] = await Promise.all([api.branches(), api.guests()])
        setBranches(b); setGuests(g)
        if (b.length) setBranchId(b[0].branchId)
      } catch (e) {
        setBootError(`Could not load data — is the backend running with the Vite proxy target on :8080? (${e.message})`)
      }
    })()
  }, [token])

  if (!token) return <LoginPage />

  return (
    <div className="shell">
      <Sidebar page={page} onNavigate={setPage} />
      <main className="content">
        {bootError && <Banner kind="error" onClose={() => setBootError(null)}>{bootError}</Banner>}
        {page === 'rooms' && (
          <RoomsPage branches={branches} branchId={branchId} setBranchId={setBranchId} />
        )}
        {page === 'reservations' && <ReservationsPage guests={guests} />}
        {page === 'guests' && <GuestsPage guests={guests} refreshGuests={refreshGuests} />}
        {page === 'billing' && <BillingPage guests={guests} />}
        <footer className="foot">Live against PostgreSQL on Render · constraints enforced at the database layer</footer>
      </main>
    </div>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <Shell />
    </AuthProvider>
  )
}
