// No real photography yet — a tasteful placeholder that reads as
// "room photo goes here" rather than a broken image or empty box.
export default function PhotoPlaceholder({ label }) {
  return (
    <div className="photo-placeholder" role="img" aria-label={label ?? 'Room photo placeholder'}>
      <svg viewBox="0 0 64 64" width="28" height="28" fill="none" stroke="currentColor" strokeWidth="1.4">
        <rect x="8" y="16" width="48" height="34" rx="2" />
        <circle cx="22" cy="28" r="4" />
        <path d="M8 44l14-12 10 8 8-6 16 14" />
      </svg>
    </div>
  )
}
