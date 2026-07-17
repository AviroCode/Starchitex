import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'

const REJECTION_HINT = 'The database rejected this action — the reservation may already be in a state that does not allow it.'

export default function MyReservationsPage({ guestId }) {
  const [reservations, setReservations] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const load = () => api.reservationsByGuest(guestId).then(setReservations).catch((e) => setError(e.message))
  useEffect(() => { load() }, [guestId])

  const actionsFor = (r) => {
    switch (r.status) {
      case 'Pending':    return [['Cancel', api.cancelReservation, 'cancelled']]
      case 'Confirmed':  return [['Check in', api.checkInReservation, 'checked in'], ['Cancel', api.cancelReservation, 'cancelled']]
      case 'Checked In': return [['Check out', api.checkOutReservation, 'checked out']]
      default:           return []
    }
  }

  const run = async (r, action, verb) => {
    setError(null); setNotice(null)
    try {
      await action(r.reservationId)
      setNotice(`Reservation ${r.reservationId} ${verb}.`)
      load()
    } catch {
      setError(REJECTION_HINT)
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>My Reservations</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="panel panel-grow">
        <table className="res-table">
          <thead>
            <tr><th>ID</th><th>Check-in</th><th>Check-out</th><th>Guests</th><th>Status</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {reservations.slice().reverse().map((r) => (
              <tr key={r.reservationId}>
                <td className="mono">{r.reservationId}</td>
                <td className="mono">{r.checkInDate}</td>
                <td className="mono">{r.checkOutDate}</td>
                <td className="mono">{r.numOfGuests}</td>
                <td><StatusBadge value={r.status} /></td>
                <td className="actions">
                  {actionsFor(r).length > 0
                    ? actionsFor(r).map(([label, action, verb]) => (
                        <button key={label} className="mini-btn" onClick={() => run(r, action, verb)}>{label}</button>
                      ))
                    : <span className="actions-empty">—</span>}
                </td>
              </tr>
            ))}
            {reservations.length === 0 && (
              <tr><td colSpan="6" className="empty">No reservations yet — book a room to see it here.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}
