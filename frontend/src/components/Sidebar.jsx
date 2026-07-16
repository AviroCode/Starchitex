import { useAuth } from '../context/AuthContext.jsx'

const NAV = [
  { id: 'rooms',        label: 'Rooms' },
  { id: 'reservations', label: 'Reservations' },
  { id: 'guests',       label: 'Guests' },
  { id: 'billing',      label: 'Billing' },
]

export default function Sidebar({ page, onNavigate }) {
  const { username, logout } = useAuth()
  return (
    <aside className="sidebar">
      <div className="brand">
        <h1>Starchitex</h1>
        <p className="tagline">Front Desk Console</p>
      </div>
      <nav>
        {NAV.map((n) => (
          <button
            key={n.id}
            className={`nav-item ${page === n.id ? 'active' : ''}`}
            onClick={() => onNavigate(n.id)}
          >
            {n.label}
          </button>
        ))}
      </nav>
      <div className="sidebar-foot">
        <span className="whoami">{username}</span>
        <button className="link-btn" onClick={logout}>Sign out</button>
      </div>
    </aside>
  )
}
