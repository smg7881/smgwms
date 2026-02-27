import { COMMON_RENDERER_REGISTRY } from "controllers/ag_grid/renderers/common"
import { ACTION_RENDERER_REGISTRY } from "controllers/ag_grid/renderers/actions"

export const RENDERER_REGISTRY = {
  ...COMMON_RENDERER_REGISTRY,
  ...ACTION_RENDERER_REGISTRY
}

