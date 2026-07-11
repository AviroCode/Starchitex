export default function Banner({ kind = 'ok', children, onClose }) {
  return (
    <div className={`banner banner-${kind}`} role={kind === 'error' ? 'alert' : 'status'}>
      <span>{children}</span>
      {onClose && <button className="banner-x" onClick={onClose} aria-label="Dismiss">×</button>}
    </div>
  )
}
