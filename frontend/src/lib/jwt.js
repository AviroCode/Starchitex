// Decodes a JWT payload client-side (no verification — the token was
// already verified server-side; this is purely for reading the claims the
// backend embedded, so the UI can pick the right console for the role).
export function decodeJwt(token) {
  try {
    const payload = token.split('.')[1]
    const base64 = payload.replace(/-/g, '+').replace(/_/g, '/')
    const json = atob(base64)
    return JSON.parse(json)
  } catch {
    return null
  }
}
