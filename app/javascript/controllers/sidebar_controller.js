import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["treeChildren"]

  toggleTree(event) {
    const button = event.currentTarget
    const children = button.nextElementSibling

    if (children && children.classList.contains("nav-tree-children")) {
      button.classList.toggle("expanded")
      children.classList.toggle("open")
    }
  }
}
