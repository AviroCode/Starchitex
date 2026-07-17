import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'

export default function Sidebar({ tagline, navSections }) {
  const { username, logout } = useAuth()
  return (
    <aside className="sidebar">
      <div className="brand">
        <h1>Starchitex</h1>
        <p className="tagline">{tagline}</p>
      </div>
      <nav>
        {navSections.map((section, i) => (
          <div className="nav-section" key={section.label ?? `s${i}`}>
            {section.label && <p className="nav-section-label">{section.label}</p>}
            {section.items.map((n) => (
              <NavLink
                key={n.path}
                to={n.path}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
              >
                {n.label}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>
      <div className="sidebar-foot">
        <span className="whoami">{username}</span>
        <button className="link-btn" onClick={logout}>Sign out</button>
      </div>
    </aside>
  )
}
