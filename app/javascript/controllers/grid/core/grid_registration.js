import { resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { isApiAlive } from "controllers/grid/core/api_guard"

export function registerGridInstance(event, context, configs, onAllReady) {
  const registration = resolveAgGridRegistration(event)
  if (!registration) return

  const { gridElement, api, controller } = registration

  for (const config of configs) {
    if (!config.target || gridElement !== config.target) continue

    if (config.isMaster && typeof config.setup === "function") {
      config.setup(event)
    } else {
      const { controllerKey, managerKey, configMethod } = config

      if (typeof managerKey === "string" && context[managerKey]) {
        context[managerKey].detach?.()
      }

      if (controllerKey) {
        context[controllerKey] = controller
      }

      if (managerKey && configMethod && typeof context[configMethod] === "function") {
        context[managerKey] = new GridCrudManager(context[configMethod]())
        context[managerKey].attach(api)
      }
    }
    break
  }

  let allManagersReady = true
  for (const config of configs) {
    let isReady = false

    if (config.isMaster) {
      if (context.manager && isApiAlive(context.manager.api)) isReady = true
      else if (context._singleGridApi) isReady = true
    } else {
      if (config.managerKey && context[config.managerKey] && isApiAlive(context[config.managerKey].api)) {
        isReady = true
      } else if (config.controllerKey && context[config.controllerKey] && isApiAlive(context[config.controllerKey].api)) {
        isReady = true
      }
    }

    if (!isReady) {
      allManagersReady = false
      break
    }
  }

  if (allManagersReady && typeof onAllReady === "function") {
    onAllReady()
  }
}

