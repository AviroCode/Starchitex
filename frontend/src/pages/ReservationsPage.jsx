import { useEffect, useState } from 'react'
import { api } from '../api/client.js'
import Banner from '../components/Banner.jsx'
import StatusBadge from '../components/StatusBadge.jsx'

// Status values are Title Case on the live schema (FRONTEND_GUIDE.md §3).
const REJECTION_HINT =
  'The database rejected this — likely check-out is not after check-in, or a required field is invalid.'

export default function ReservationsPage({ guests, branchId }) {
  const [reservations, setReservations] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  // create form
  const [guestId, setGuestId] = useState('')
  const [checkIn, setCheckIn] = useState('')
  const [checkOut, setCheckOut] = useState('')
  const [numGuests, setNumGuests] = useState(1)
  const [saving, setSaving] = useState(false)

  const load = () => api.reservations().then(setReservations).catch((e) => setError(e.message))
  useEffect(() => { load() }, [])

  const guestName = (id) => {
    const g = guests.find((x) => x.guestId === id)
    return g ? `${g.firstName} ${g.lastName}` : id
  }

  const create = async (e) => {
    e.preventDefault()
    setSaving(true); setError(null); setNotice(null)
    try {
      await api.createReservation({
        branchId,
        guestId: Number(guestId),
        checkInDate: checkIn,
        checkOutDate: checkOut,
        actualCheckinTime: null,
        actualCheckoutTime: null,
        numOfGuests: Number(numGuests),
        status: 'Pending', // required explicitly; Title Case (§3)
      })
      setNotice('Reservation created — status Pending.')
      setGuestId(''); setCheckIn(''); setCheckOut(''); setNumGuests(1)
      load()
    } catch {
      setError(REJECTION_HINT)
    } finally {
      setSaving(false)
    }
  }

  // Status transitions call the dedicated action endpoints (each one's own
  // @PreAuthorize + service-layer validation) rather than a full-object PUT,
  // which could otherwise silently clobber unrelated fields.
  const ACTIONS = {
    Confirmed: [api.confirmReservation, 'confirmed'],
    'Checked In': [api.checkInReservation, 'checked in'],
    'Checked Out': [api.checkOutReservation, 'checked out'],
    Cancelled: [api.cancelReservation, 'cancelled'],
  }

  const transition = async (r, nextStatus) => {
    setError(null); setNotice(null)
    const [action] = ACTIONS[nextStatus]
    try {
      await action(r.reservationId)
      setNotice(
        nextStatus === 'Cancelled'
          ? `Reservation ${r.reservationId} cancelled — the database trigger has written an audit-log row.`
          : `Reservation ${r.reservationId} → ${nextStatus}.`
      )
      load()
    } catch {
      setError(REJECTION_HINT)
    }
  }

  const actionsFor = (r) => {
    switch (r.status) {
      case 'Pending':    return [['Confirm', 'Confirmed'], ['Cancel', 'Cancelled']]
      case 'Confirmed':  return [['Check in', 'Checked In'], ['Cancel', 'Cancelled']]
      case 'Checked In': return [['Check out', 'Checked Out']]
      default:           return []
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>Reservations</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>New reservation</h3>
          <form onSubmit={create} className="res-form">
            <label>Guest
              <select value={guestId} onChange={(e) => setGuestId(e.target.value)} required>
                <option value="" disabled>Choose a guest</option>
                {guests.map((g) => (
                  <option key={g.guestId} value={g.guestId}>{g.firstName} {g.lastName}</option>
                ))}
              </select>
            </label>
            <label>Check-in
              <input type="date" value={checkIn} onChange={(e) => setCheckIn(e.target.value)} required />
            </label>
            <label>Check-out
              <input type="date" value={checkOut} onChange={(e) => setCheckOut(e.target.value)} required />
            </label>
            <label>Guests
              <input type="number" min="1" value={numGuests} onChange={(e) => setNumGuests(e.target.value)} required />
            </label>
            <button type="submit" disabled={saving}>{saving ? 'Saving…' : 'Create reservation'}</button>
          </form>
        </div>

        <div className="panel panel-grow">
          <h3>All reservations</h3>
          <table className="res-table">
            <thead>
              <tr><th>ID</th><th>Guest</th><th>Check-in</th><th>Check-out</th><th>Status</th><th>Actions</th></tr>
            </thead>
            <tbody>
              {reservations.slice().reverse().map((r) => (
                <tr key={r.reservationId}>
                  <td className="mono">{r.reservationId}</td>
                  <td>{guestName(r.guestId)}</td>
                  <td className="mono">{r.checkInDate}</td>
                  <td className="mono">{r.checkOutDate}</td>
                  <td><StatusBadge value={r.status} /></td>
                  <td className="actions">
                    {actionsFor(r).map(([label, next]) => (
                      <button key={next} className="mini-btn" onClick={() => transition(r, next)}>{label}</button>
                    ))}
                  </td>
                </tr>
              ))}
              {reservations.length === 0 && (
                <tr><td colSpan="6" className="empty">No reservations yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
