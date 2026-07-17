import { useEffect, useState } from 'react'
import { api } from '../api/client.js'
import Banner from '../components/Banner.jsx'
import StatusBadge from '../components/StatusBadge.jsx'

const fmt = (n) => Number(n).toLocaleString('en-US', { minimumFractionDigits: 2 })
const PAYMENT_METHODS = ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Digital Wallet', 'Other']

export default function BillingPage({ guests }) {
  const [invoices, setInvoices] = useState([])
  const [reservations, setReservations] = useState([])
  const [roomTypes, setRoomTypes] = useState([])
  const [services, setServices] = useState([])
  const [selected, setSelected] = useState(null)
  const [items, setItems] = useState([])
  const [payments, setPayments] = useState([])
  const [invoiceRooms, setInvoiceRooms] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const [newInvoiceReservation, setNewInvoiceReservation] = useState('')
  const [itemType, setItemType] = useState('Room')
  const [itemRoomId, setItemRoomId] = useState('')
  const [itemServiceId, setItemServiceId] = useState('')
  const [itemQty, setItemQty] = useState(1)
  const [itemAmount, setItemAmount] = useState(0)
  const [itemDesc, setItemDesc] = useState('')
  const [payAmount, setPayAmount] = useState('')
  const [payMethod, setPayMethod] = useState('Cash')

  const loadInvoices = () => api.invoices().then(setInvoices).catch((e) => setError(e.message))
  useEffect(() => {
    loadInvoices()
    api.reservations().then(setReservations).catch(() => {})
    api.roomTypes().then(setRoomTypes).catch(() => {})
    api.services().then(setServices).catch(() => {})
  }, [])

  const open = async (inv) => {
    setSelected(inv); setError(null); setNotice(null)
    try {
      const [its, pays] = await Promise.all([api.invoiceItemsByInvoice(inv.invoiceId), api.paymentsByInvoice(inv.invoiceId)])
      setItems(its); setPayments(pays)
      const rooms = await api.roomsForReservation(inv.reservationId).catch(() => [])
      setInvoiceRooms(rooms)
    } catch (e) { setError(e.message) }
  }

  const refreshSelected = async () => {
    const fresh = await api.invoices().then((all) => all.find((i) => i.invoiceId === selected.invoiceId))
    setInvoices(await api.invoices())
    if (fresh) setSelected(fresh)
    const [its, pays] = await Promise.all([api.invoiceItemsByInvoice(selected.invoiceId), api.paymentsByInvoice(selected.invoiceId)])
    setItems(its); setPayments(pays)
  }

  const paid = payments.reduce((s, p) => s + Number(p.amount), 0)
  const guestName = (id) => {
    const g = guests.find((x) => x.guestId === id)
    return g ? `${g.firstName} ${g.lastName}` : id
  }
  const roomTypeName = (id) => roomTypes.find((t) => t.roomTypeId === id)?.typeName ?? id
  const serviceName = (id) => services.find((s) => s.serviceId === id)?.serviceName ?? id

  const createInvoice = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    const res = reservations.find((r) => r.reservationId === Number(newInvoiceReservation))
    if (!res) { setError('Pick a reservation first.'); return }
    try {
      // Placeholder totals — trg_recalculate_invoice_total_on_item_change
      // recomputes sub_total/tax_amount/total_amount as soon as items land.
      await api.createInvoice({
        reservationId: res.reservationId,
        payerGuestId: res.guestId,
        subTotal: 0, taxAmount: 0, discount: 0, totalAmount: 0,
        status: 'Unpaid',
      })
      setNotice(`Invoice created for reservation #${res.reservationId}.`)
      setNewInvoiceReservation('')
      loadInvoices()
    } catch {
      setError('Could not create the invoice for that reservation.')
    }
  }

  const addItem = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createInvoiceItem({
        invoiceId: selected.invoiceId,
        roomId: itemType === 'Room' ? Number(itemRoomId) : null,
        serviceId: itemType === 'Service' ? Number(itemServiceId) : null,
        itemType,
        quantity: Number(itemQty),
        // Ignored by the trigger for Room/Service (auto-priced from the
        // catalog) — only used as-entered for Damage/Maintenance/Other.
        amount: Number(itemAmount) || 0,
        description: itemDesc || null,
      })
      setNotice('Item added — total recalculated by the database.')
      setItemRoomId(''); setItemServiceId(''); setItemQty(1); setItemAmount(0); setItemDesc('')
      refreshSelected()
    } catch {
      setError('Could not add that item — check the room/service is selected correctly.')
    }
  }

  const recordPayment = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createPayment({ invoiceId: selected.invoiceId, amount: Number(payAmount), paymentMethod: payMethod })
      setNotice('Payment recorded — invoice status recalculated by the database.')
      setPayAmount('')
      refreshSelected()
    } catch {
      setError('Payment rejected — it likely exceeds the outstanding balance (the database blocks overpayment).')
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>Billing</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>New invoice</h3>
          <form onSubmit={createInvoice} className="res-form">
            <label>Reservation
              <select value={newInvoiceReservation} onChange={(e) => setNewInvoiceReservation(e.target.value)} required>
                <option value="" disabled>Choose a reservation</option>
                {reservations.map((r) => (
                  <option key={r.reservationId} value={r.reservationId}>#{r.reservationId} — {guestName(r.guestId)} ({r.status})</option>
                ))}
              </select>
            </label>
            <button type="submit">Create invoice</button>
          </form>

          {selected && (
            <>
              <h3 style={{ marginTop: '1.2rem' }}>Add item to #{selected.invoiceId}</h3>
              <form onSubmit={addItem} className="res-form">
                <label>Type
                  <select value={itemType} onChange={(e) => setItemType(e.target.value)}>
                    <option>Room</option><option>Service</option><option>Damage</option><option>Maintenance</option><option>Other</option>
                  </select>
                </label>
                {itemType === 'Room' && (
                  <label>Room
                    <select value={itemRoomId} onChange={(e) => setItemRoomId(e.target.value)} required>
                      <option value="" disabled>Choose a room</option>
                      {invoiceRooms.map((r) => <option key={r.roomId} value={r.roomId}>{r.roomNumber} — {roomTypeName(r.roomTypeId)}</option>)}
                    </select>
                  </label>
                )}
                {itemType === 'Service' && (
                  <label>Service
                    <select value={itemServiceId} onChange={(e) => setItemServiceId(e.target.value)} required>
                      <option value="" disabled>Choose a service</option>
                      {services.map((s) => <option key={s.serviceId} value={s.serviceId}>{s.serviceName}</option>)}
                    </select>
                  </label>
                )}
                <label>Quantity<input type="number" min="1" value={itemQty} onChange={(e) => setItemQty(e.target.value)} required /></label>
                {['Damage', 'Maintenance', 'Other'].includes(itemType) && (
                  <label>Amount<input type="number" min="0" step="0.01" value={itemAmount} onChange={(e) => setItemAmount(e.target.value)} required /></label>
                )}
                <label>Note<input value={itemDesc} onChange={(e) => setItemDesc(e.target.value)} /></label>
                <button type="submit">Add item</button>
              </form>

              <h3 style={{ marginTop: '1.2rem' }}>Record payment</h3>
              <form onSubmit={recordPayment} className="res-form">
                <label>Amount<input type="number" min="0.01" step="0.01" value={payAmount} onChange={(e) => setPayAmount(e.target.value)} required /></label>
                <label>Method
                  <select value={payMethod} onChange={(e) => setPayMethod(e.target.value)}>
                    {PAYMENT_METHODS.map((m) => <option key={m}>{m}</option>)}
                  </select>
                </label>
                <button type="submit">Record payment</button>
              </form>
            </>
          )}
        </div>

        <div className="panel panel-grow">
          <h3>Invoices</h3>
          <table className="res-table">
            <thead>
              <tr><th>ID</th><th>Reservation</th><th>Payer</th><th>Total</th><th>Status</th><th></th></tr>
            </thead>
            <tbody>
              {invoices.slice().reverse().map((i) => (
                <tr key={i.invoiceId} className={selected?.invoiceId === i.invoiceId ? 'row-active' : ''}>
                  <td className="mono">{i.invoiceId}</td>
                  <td className="mono">#{i.reservationId}</td>
                  <td>{guestName(i.payerGuestId)}</td>
                  <td className="mono">฿ {fmt(i.totalAmount)}</td>
                  <td><StatusBadge value={i.status} /></td>
                  <td><button className="mini-btn" onClick={() => open(i)}>Open</button></td>
                </tr>
              ))}
              {invoices.length === 0 && <tr><td colSpan="6" className="empty">No invoices yet.</td></tr>}
            </tbody>
          </table>

          {selected && (
            <div className="folio" style={{ marginTop: '1.4rem' }}>
              <h4>Invoice #{selected.invoiceId} folio</h4>
              <dl>
                <div><dt>Sub-total</dt><dd className="mono">฿ {fmt(selected.subTotal)}</dd></div>
                <div><dt>Tax (7%)</dt><dd className="mono">฿ {fmt(selected.taxAmount)}</dd></div>
                <div><dt>Discount</dt><dd className="mono">− ฿ {fmt(selected.discount)}</dd></div>
                <div className="folio-total"><dt>Total</dt><dd className="mono">฿ {fmt(selected.totalAmount)}</dd></div>
                <div><dt>Paid</dt><dd className="mono">฿ {fmt(paid)}</dd></div>
                <div><dt>Balance</dt><dd className="mono">฿ {fmt(selected.totalAmount - paid)}</dd></div>
              </dl>

              <h4>Line items</h4>
              {items.length === 0 && <p className="empty">No items yet.</p>}
              {items.map((it) => (
                <div className="pay-row" key={it.invoiceItemId}>
                  <span>{it.itemType}{it.roomId ? ` — room ${it.roomId}` : ''}{it.serviceId ? ` — ${serviceName(it.serviceId)}` : ''}</span>
                  <span className="mono dim">× {it.quantity}</span>
                  <span className="mono">฿ {fmt(it.amount)}</span>
                </div>
              ))}

              <h4>Payments</h4>
              {payments.length === 0 && <p className="empty">No payments yet.</p>}
              {payments.map((p) => (
                <div className="pay-row" key={p.paymentId}>
                  <span className="mono">฿ {fmt(p.amount)}</span>
                  <span>{p.paymentMethod}</span>
                  <span className="mono dim">{p.transactionRef || '—'}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  )
}
