import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'

const MONTHS = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const fmtMoney = (n) => Number(n ?? 0).toLocaleString('en-US', { minimumFractionDigits: 2 })
const fmtPct = (n) => `${(Number(n ?? 0) * 100).toFixed(1)}%`

export default function AnalyticsPage() {
  const [summary, setSummary] = useState(null)
  const [revenue, setRevenue] = useState([])
  const [error, setError] = useState(null)

  useEffect(() => {
    api.analyticsSummary().then(setSummary).catch((e) => setError(e.message))
    api.monthlyRevenue().then(setRevenue).catch((e) => setError(e.message))
  }, [])

  return (
    <section className="page">
      <header className="page-head"><h2>Analytics</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}

      {summary && (
        <div className="panel">
          <h3>This period</h3>
          <div className="stat-row">
            <div className="stat-tile">
              <span className="stat-label">Occupancy (today)</span>
              <span className="stat-value mono">{fmtPct(summary.occupancyRateToday)}</span>
              <span className="dim">{summary.occupiedToday} / {summary.totalRooms} rooms</span>
            </div>
            <div className="stat-tile">
              <span className="stat-label">ADR (this month)</span>
              <span className="stat-value mono">฿ {fmtMoney(summary.adr)}</span>
              <span className="dim">{summary.roomNightsThisMonth} room-nights sold</span>
            </div>
            <div className="stat-tile">
              <span className="stat-label">RevPAR (this month)</span>
              <span className="stat-value mono">฿ {fmtMoney(summary.revpar)}</span>
              <span className="dim">฿ {fmtMoney(summary.revenueThisMonth)} revenue</span>
            </div>
          </div>
          <p className="hint">
            ADR (Average Daily Rate) = revenue this month ÷ room-nights sold this month.
            RevPAR (Revenue Per Available Room) = revenue this month ÷ (total rooms × days elapsed this month).
            Both computed live from Reservation/RoomAvailability/Invoice data, not hardcoded.
          </p>
        </div>
      )}

      <div className="panel panel-grow">
        <h3>Monthly revenue</h3>
        <table className="res-table">
          <thead><tr><th>Month</th><th>Invoices</th><th>Revenue</th></tr></thead>
          <tbody>
            {revenue.map((r) => (
              <tr key={`${r.invoiceYear}-${r.invoiceMonth}`}>
                <td>{MONTHS[r.invoiceMonth]} {r.invoiceYear}</td>
                <td className="mono">{r.totalInvoices}</td>
                <td className="mono">฿ {fmtMoney(r.totalRevenue)}</td>
              </tr>
            ))}
            {revenue.length === 0 && <tr><td colSpan="3" className="empty">No paid invoices yet this year.</td></tr>}
          </tbody>
        </table>
        <p className="hint">Refreshed automatically every night at 2 AM (materialized view), and reflects only invoices with status Paid.</p>
      </div>
    </section>
  )
}
