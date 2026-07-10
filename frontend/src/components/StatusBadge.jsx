export default function StatusBadge({ value }) {
  const key = String(value || '').replace(/\s/g, '').toLowerCase()
  return <span className={`status status-${key}`}>{value}</span>
}
