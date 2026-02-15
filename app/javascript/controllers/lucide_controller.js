import { Controller } from "@hotwired/stimulus"
import { createIcons, icons } from "lucide"

export default class extends Controller {
  connect() {
    this.renderIcons = this.renderIcons.bind(this)
    this.renderIcons()
    document.addEventListener("turbo:load", this.renderIcons)
    document.addEventListener("turbo:frame-load", this.renderIcons)
    document.addEventListener("turbo:render", this.renderIcons)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.renderIcons)
    document.removeEventListener("turbo:frame-load", this.renderIcons)
    document.removeEventListener("turbo:render", this.renderIcons)
  }

  renderIcons() {
    createIcons({ icons })
  }
}
