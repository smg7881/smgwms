export function isApiAlive(api) {
  return Boolean(api) && !(typeof api.isDestroyed === "function" && api.isDestroyed())
}

