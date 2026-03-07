export function isLookupColumnDef(colDef) {
  if (!colDef) return false
  if (colDef.context?.lookup_popup_type) return true
  return Boolean(colDef.lookup_popup_type)
}

export function buildColumnDefs(columns, {
  formatterRegistry = {},
  rendererRegistry = {},
  isLookupColumn = isLookupColumnDef
} = {}) {
  return columns.map((column) => {
    const def = { ...column }

    def.context = def.context || {}
    Object.keys(def).forEach((key) => {
      if (key.startsWith("lookup_")) {
        def.context[key] = def[key]
        delete def[key]
      }
    })

    const hasLookupPopup = isLookupColumn(def)
    if (hasLookupPopup) {
      if (!def.context.lookup_name_field && def.field) {
        def.context.lookup_name_field = def.field
      }
      if (!def.cellRenderer) {
        def.cellRenderer = "lookupPopupCellRenderer"
      }
      def.editable = false
    }

    if (def.formatter && formatterRegistry[def.formatter]) {
      def.valueFormatter = formatterRegistry[def.formatter]
      delete def.formatter
    }

    if (def.cellRenderer && rendererRegistry[def.cellRenderer]) {
      def.cellRenderer = rendererRegistry[def.cellRenderer]
    }

    if (def.editable === true) {
      def.editable = (params) => !params?.data?.__is_deleted
    }

    return def
  })
}

