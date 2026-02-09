import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]
  static values = { text: String }

  connect() {
    this.panelTarget.querySelector("p").textContent = this.textValue || ""
    this._outside = (e) => this.closeOnOutside(e)
    window.addEventListener("click", this._outside)
  }

  disconnect() {
    window.removeEventListener("click", this._outside)
  }

  toggle(event) {
    event?.stopPropagation()
    this.panelTarget.classList.toggle("hidden")
  }

  closeOnOutside(event) {
    if (this.element.contains(event.target)) return
    this.panelTarget.classList.add("hidden")
  }
}
