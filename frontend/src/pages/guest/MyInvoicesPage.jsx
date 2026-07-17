import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'

const fmt = (n) => Number(n).toLocaleString('en-US', { minimumFractionDigits: 2 })

export default function MyInvoicesPage({ guestId }) {
  const [invoices, setInvoices] = useState([])
  const [selected, setSelected] = useState(null)
  const [payments, setPayments] = useState([])
  const [error, setError] = useState(null)

  useEffect(() => {
    api.invoicesByGuest(guestId).then(setInvoices).catch((e) => setError(e.message))
  }, [guestId])

  const open = async (inv) => {
    setSelected(inv)
    try { setPayments(await api.paymentsByInvoice(inv.invoiceId)) }
    catch (e) { setError(e.message) }
  }

  const paid = payments.reduce((s, p) => s + Number(p.amount), 0)

  return (
    <section className="page">
      <header className="page-head"><h2>My Invoices</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}

      <div className="two-col">
        <div className="panel panel-grow">
          <h3>Invoices</h3>
          <table className="res-table">
            <thead>
              <tr><th>ID</th><th>Reservation</th><th>Total</th><th>Status</th><th></th></tr>
            </thead>
            <tbody>
              {invoices.map((i) => (
                <tr key={i.invoiceId} className={selected?.invoiceId === i.invoiceId ? 'row-active' : ''}>
                  <td className="mono">{i.invoiceId}</td>
                  <td className="mono">#{i.reservationId}</td>
                  <td className="mono">฿ {fmt(i.totalAmount)}</td>
                  <td><StatusBadge value={i.status} /></td>
                  <td><button className="mini-btn" onClick={() => open(i)}>Open</button></td>
                </tr>
              ))}
              {invoices.length === 0 && (
                <tr><td colSpan="5" className="empty">No invoices yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="panel">
          <h3>{selected ? `Invoice #${selected.invoiceId}` : 'Select an invoice'}</h3>
          {selected && (
            <div className="folio">
              <dl>
                <div><dt>Sub-total</dt><dd className="mono">฿ {fmt(selected.subTotal)}</dd></div>
                <div><dt>Tax (7%)</dt><dd className="mono">฿ {fmt(selected.taxAmount)}</dd></div>
                <div><dt>Discount</dt><dd className="mono">− ฿ {fmt(selected.discount)}</dd></div>
                <div className="folio-total"><dt>Total</dt><dd className="mono">฿ {fmt(selected.totalAmount)}</dd></div>
                <div><dt>Paid</dt><dd className="mono">฿ {fmt(paid)}</dd></div>
                <div><dt>Balance</dt><dd className="mono">฿ {fmt(selected.totalAmount - paid)}</dd></div>
              </dl>
              <h4>Payments</h4>
              {payments.length === 0 && <p className="empty">No payments recorded yet.</p>}
              {payments.map((p) => (
                <div className="pay-row" key={p.paymentId}>
                  <span className="mono">฿ {fmt(p.amount)}</span>
                  <span>{p.paymentMethod}</span>
                  <span className="mono dim">{p.transactionRef || '—'}</span>
                </div>
              ))}
              <p className="hint">Payments are recorded by front-desk staff — this view is read-only.</p>
            </div>
          )}
        </div>
      </div>
    </section>
  )
}
