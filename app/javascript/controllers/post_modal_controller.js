import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "frame", "closeSignal"]

  connect() {
    console.log("[PostModalController] connected")
    this.observer = new MutationObserver(() => {
      const node = this.closeSignalTarget.firstElementChild
      if (!node) return

      const redirectTo = node.dataset.redirectTo
      this.close()
      if (redirectTo) Turbo.visit(redirectTo)
    })
    this.observer.observe(this.closeSignalTarget, { childList: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  open() {
    console.log("OPEN CALLED")
    this.frameTarget.src = "/posts/new"
    this.modalTarget.classList.remove("hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
    this.closeSignalTarget.innerHTML = ""
  }

  backdrop(e) {
    if (e.target === this.modalTarget) this.close()
  }
}
