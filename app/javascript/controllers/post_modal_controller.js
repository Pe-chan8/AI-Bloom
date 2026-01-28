import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "frame", "closeSignal"]

  connect() {
    console.log("[PostModalController] connected")
    // turbo-stream append を監視して閉じる
    this.observer = new MutationObserver(() => {
      if (this.closeSignalTarget.childNodes.length > 0) this.close()
    })
    this.observer.observe(this.closeSignalTarget, { childList: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  open() {
    this.frameTarget.src = "/posts/new"
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
    this.closeSignalTarget.innerHTML = ""
  }

  backdrop(e) {
    if (e.target === this.modalTarget) this.close()
  }
}
