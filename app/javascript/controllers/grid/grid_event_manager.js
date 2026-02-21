import { isApiAlive } from "controllers/grid/grid_utils"

const AG_GRID_SELECTOR = "[data-controller='ag-grid']"

export function resolveAgGridRegistration(event) {
  const gridElement = event?.target?.closest?.(AG_GRID_SELECTOR)
  if (!gridElement) return null

  const { api, controller } = event.detail || {}
  if (!api) return null

  return { gridElement, api, controller }
}

export function rowDataFromGridEvent(api, event) {
  if (event?.data) return event.data
  if (!isApiAlive(api)) return null
  if (typeof event?.rowIndex !== "number" || event.rowIndex < 0) return null

  return api.getDisplayedRowAtIndex(event.rowIndex)?.data || null
}

export class GridEventManager {
  constructor() {
    this.bindings = []
  }

  bind(api, eventName, handler) {
    if (!isApiAlive(api) || !eventName || !handler) return

    api.addEventListener(eventName, handler)
    this.bindings.push({ api, eventName, handler })
  }

  unbindAll() {
    this.bindings.forEach(({ api, eventName, handler }) => {
      if (!isApiAlive(api)) return
      api.removeEventListener(eventName, handler)
    })
    this.bindings = []
  }
}
