import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "frame"]

  connect() {
    console.log("✅ post-modal controller connected!", this.element)
  }

  open() {
    console.log("🔔 open called")
    this.overlayTarget.classList.remove("hidden")

    fetch("/posts/new")
      .then((res) => res.text())
      .then((html) => {
        this.frameTarget.innerHTML = html
      })
  }

  close(event) {
    console.log("🔔 close called")
    event.preventDefault()
    this.overlayTarget.classList.add("hidden")
    this.frameTarget.innerHTML = ""
  }
}
