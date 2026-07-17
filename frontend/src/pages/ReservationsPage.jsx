import { useEffect, useState } from 'react'
import { api } from '../api/client.js'
import Banner from '../components/Banner.jsx'
import StatusBadge from '../components/StatusBadge.jsx'
import ConfirmDialog from '../components/ConfirmDialog.jsx'

// Mirrors backend/src/main/resources/schema.sql's enforce_cancellation_policy:
// check_in_date - CURRENT_DATE <= 1 triggers a one-night cancellation fee.
const daysUntil = (dateStr) => Math.round((new Date(dateStr) - new Date(todayISO())) / 86400000)

// Status values are Title Case on the live schema (FRONTEND_GUIDE.md §3).
const REJECTION_HINT =
  'The database rejected this — likely check-out is not after check-in, or a required field is invalid.'

// Local calendar date (not UTC) so "today" matches what the date picker shows.
const todayISO = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export default function ReservationsPage({ guests, branchId }) {
  const today = todayISO()
  const [reservations, setReservations] = useState([])
  const [rooms, setRooms] = useState([])
  const [outOfServiceRoomIds, setOutOfServiceRoomIds] = useState(new Set())
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  // create form
  const [guestId, setGuestId] = useState('')
  const [roomId, setRoomId] = useState('')
  const [checkIn, setCheckIn] = useState('')
  const [checkOut, setCheckOut] = useState('')
  const [numGuests, setNumGuests] = useState(1)
  const [specialRequests, setSpecialRequests] = useState('')
  const [saving, setSaving] = useState(false)
  const [pendingBooking, setPendingBooking] = useState(null)
  const [pendingCancel, setPendingCancel] = useState(null)

  const load = () => api.reservations().then(setReservations).catch((e) => setError(e.message))
  useEffect(() => { load() }, [])

  useEffect(() => {
    if (branchId == null) return
    api.roomsByBranch(branchId).then(setRooms).catch(() => {})
  }, [branchId])

  useEffect(() => {
    api.roomMaintenances().then((tickets) => {
      setOutOfServiceRoomIds(new Set(tickets.filter((t) => t.status !== 'Completed').map((t) => t.roomId)))
    }).catch(() => {})
  }, [])

  const guestName = (id) => {
    const g = guests.find((x) => x.guestId === id)
    return g ? `${g.firstName} ${g.lastName}` : id
  }
  const roomLabel = (id) => rooms.find((r) => r.roomId === id)?.roomNumber ?? id

  // Opens the confirm overlay instead of booking instantly.
  const requestCreate = (e) => {
    e.preventDefault()
    if (checkIn < today) { setError('Check-in date can\'t be in the past.'); return }
    if (checkOut <= checkIn) { setError('Check-out date must be after check-in.'); return }
    setError(null); setNotice(null)
    setPendingBooking({ guestId: Number(guestId), roomId: Number(roomId) })
  }

  const confirmCreate = async () => {
    setSaving(true); setError(null); setNotice(null)
    try {
      await api.bookRoom({
        branchId,
        guestId: pendingBooking.guestId,
        checkInDate: checkIn,
        checkOutDate: checkOut,
        numOfGuests: Number(numGuests),
        specialRequests: specialRequests || null,
        roomId: pendingBooking.roomId,
      })
      setNotice('Reservation created — status Pending.')
      setGuestId(''); setRoomId(''); setCheckIn(''); setCheckOut(''); setNumGuests(1); setSpecialRequests('')
      setPendingBooking(null)
      load()
    } catch {
      setError(REJECTION_HINT)
      setPendingBooking(null)
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

  // Cancelling within 24h of check-in triggers a DB-enforced cancellation
  // fee (enforce_cancellation_policy) — warn before firing it. Other
  // transitions go straight through, unchanged.
  const requestAction = (r, nextStatus) => {
    if (nextStatus === 'Cancelled' && daysUntil(r.checkInDate) <= 1) {
      setPendingCancel(r)
      return
    }
    transition(r, nextStatus)
  }

  const confirmCancel = async () => {
    const r = pendingCancel
    setPendingCancel(null)
    await transition(r, 'Cancelled')
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
          <form onSubmit={requestCreate} className="res-form">
            <label>Guest
              <select value={guestId} onChange={(e) => setGuestId(e.target.value)} required>
                <option value="" disabled>Choose a guest</option>
                {guests.map((g) => (
                  <option key={g.guestId} value={g.guestId}>{g.firstName} {g.lastName}</option>
                ))}
              </select>
            </label>
            <label>Room
              <select value={roomId} onChange={(e) => setRoomId(e.target.value)} required>
                <option value="" disabled>Choose a room</option>
                {rooms.map((r) => (
                  <option key={r.roomId} value={r.roomId} disabled={outOfServiceRoomIds.has(r.roomId)}>
                    {r.roomNumber}{outOfServiceRoomIds.has(r.roomId) ? ' — out of service' : ''}
                  </option>
                ))}
              </select>
            </label>
            <label>Check-in
              <input type="date" min={today} value={checkIn}
                onChange={(e) => {
                  setCheckIn(e.target.value)
                  if (checkOut && checkOut <= e.target.value) setCheckOut('')
                }} required />
            </label>
            <label>Check-out
              <input type="date" min={checkIn || today} value={checkOut} onChange={(e) => setCheckOut(e.target.value)} required />
            </label>
            <label>Guests
              <input type="number" min="1" value={numGuests} onChange={(e) => setNumGuests(e.target.value)} required />
            </label>
            <label>Special requests
              <input value={specialRequests} onChange={(e) => setSpecialRequests(e.target.value)} placeholder="e.g. non-smoking, extra pillows" />
            </label>
            <button type="submit" disabled={saving}>{saving ? 'Saving…' : 'Create reservation'}</button>
          </form>
        </div>

        <div className="panel panel-grow">
          <h3>All reservations</h3>
          <table className="res-table">
            <thead>
              <tr><th>ID</th><th>Guest</th><th>Check-in</th><th>Check-out</th><th>Requests</th><th>Status</th><th>Actions</th></tr>
            </thead>
            <tbody>
              {reservations.slice().reverse().map((r) => (
                <tr key={r.reservationId}>
                  <td className="mono">{r.reservationId}</td>
                  <td>{guestName(r.guestId)}</td>
                  <td className="mono">{r.checkInDate}</td>
                  <td className="mono">{r.checkOutDate}</td>
                  <td className="dim" title={r.specialRequests || ''}>{r.specialRequests ? (r.specialRequests.length > 24 ? r.specialRequests.slice(0, 24) + '…' : r.specialRequests) : '—'}</td>
                  <td><StatusBadge value={r.status} /></td>
                  <td className="actions">
                    {actionsFor(r).length > 0
                      ? actionsFor(r).map(([label, next]) => (
                          <button key={next} className="mini-btn" onClick={() => requestAction(r, next)}>{label}</button>
                        ))
                      : <span className="actions-empty">—</span>}
                  </td>
                </tr>
              ))}
              {reservations.length === 0 && (
                <tr><td colSpan="7" className="empty">No reservations yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {pendingBooking && (
        <ConfirmDialog
          title="Confirm new reservation"
          confirmLabel="Create reservation"
          busy={saving}
          onConfirm={confirmCreate}
          onCancel={() => setPendingBooking(null)}
        >
          <dl>
            <div><dt>Guest</dt><dd>{guestName(pendingBooking.guestId)}</dd></div>
            <div><dt>Room</dt><dd>{roomLabel(pendingBooking.roomId)}</dd></div>
            <div><dt>Dates</dt><dd>{checkIn} → {checkOut}</dd></div>
            <div><dt>Guests</dt><dd>{numGuests}</dd></div>
            {specialRequests && <div><dt>Requests</dt><dd>{specialRequests}</dd></div>}
          </dl>
        </ConfirmDialog>
      )}

      {pendingCancel && (
        <ConfirmDialog
          title="Cancel this reservation?"
          confirmLabel="Cancel reservation"
          onConfirm={confirmCancel}
          onCancel={() => setPendingCancel(null)}
        >
          <p>
            Reservation {pendingCancel.reservationId} checks in {pendingCancel.checkInDate} —
            this is within 24 hours of check-in, so a one-night cancellation fee will be added
            to the guest's folio automatically.
          </p>
        </ConfirmDialog>
      )}
    </section>
  )
}
