import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleTree(event) {
    const button = event.currentTarget
    const children = button.nextElementSibling
    if (!children || !children.classList.contains("nav-tree-children")) return

    const expanded = button.classList.toggle("expanded")
    children.classList.toggle("open", expanded)
    button.setAttribute("aria-expanded", expanded ? "true" : "false")
  }
}
