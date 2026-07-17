// Reusable review-before-you-commit overlay — used anywhere an action
// shouldn't fire the instant a button is clicked (booking a room,
// cancelling within the fee window, etc).
export default function ConfirmDialog({ title, onConfirm, onCancel, confirmLabel = 'Confirm', busy = false, children }) {
  return (
    <div className="dialog-backdrop" role="dialog" aria-modal="true" aria-label={title}>
      <div className="dialog-card panel">
        <h3>{title}</h3>
        <div className="dialog-body">{children}</div>
        <div className="dialog-actions">
          <button type="button" className="mini-btn" onClick={onCancel} disabled={busy}>Cancel</button>
          <button type="button" onClick={onConfirm} disabled={busy}>{busy ? 'Working…' : confirmLabel}</button>
        </div>
      </div>
    </div>
  )
}
