import { Controller } from "@hotwired/stimulus"
import { icons } from "lucide"

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
    document.querySelectorAll("[data-lucide]").forEach((element) => {
      this.replaceWithSvg(element)
    })
  }

  replaceWithSvg(element) {
    if (!element || element.tagName.toLowerCase() === "svg") return

    const requestedName = (element.getAttribute("data-lucide") || "").trim()
    const icon = this.resolveIcon(requestedName) || this.resolveIcon("circle")
    if (!icon) return

    const iconNode = this.extractIconNode(icon)
    if (!Array.isArray(iconNode)) return

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    const defaultAttrs = {
      xmlns: "http://www.w3.org/2000/svg",
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2",
      "stroke-linecap": "round",
      "stroke-linejoin": "round"
    }

    Object.entries(defaultAttrs).forEach(([key, value]) => {
      svg.setAttribute(key, value)
    })

    const className = element.getAttribute("class")
    if (className) {
      svg.setAttribute("class", className)
    }

    const ariaHidden = element.getAttribute("aria-hidden")
    if (ariaHidden) {
      svg.setAttribute("aria-hidden", ariaHidden)
    }

    iconNode.forEach((node) => {
      const child = this.buildSvgNode(node)
      if (child) svg.appendChild(child)
    })

    element.replaceWith(svg)
  }

  buildSvgNode(node) {
    if (!Array.isArray(node) || node.length < 2) return null

    const [tagName, attrs, children] = node
    if (typeof tagName !== "string" || typeof attrs !== "object" || attrs === null) return null

    const el = document.createElementNS("http://www.w3.org/2000/svg", tagName)
    Object.entries(attrs).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        el.setAttribute(key, String(value))
      }
    })

    if (Array.isArray(children)) {
      children.forEach((childNode) => {
        const child = this.buildSvgNode(childNode)
        if (child) el.appendChild(child)
      })
    }

    return el
  }

  resolveIcon(iconName) {
    const normalized = iconName.replace(/_/g, "-")
    const pascal = normalized
      .split("-")
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join("")

    return icons[normalized] || icons[pascal] || null
  }

  extractIconNode(icon) {
    if (Array.isArray(icon)) return icon
    if (icon && Array.isArray(icon.iconNode)) return icon.iconNode
    return null
  }
}
