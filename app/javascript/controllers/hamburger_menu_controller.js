import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "panel"]

  connect() {
    this._onKeydown = this.onKeydown.bind(this)
  }

  open() {
    this.backdropTarget.classList.remove("hidden")
    // クリック透過防止
    this.backdropTarget.classList.add("block")
    this.panelTarget.classList.remove("translate-x-full")

    document.addEventListener("keydown", this._onKeydown)
  }

  close() {
    this.panelTarget.classList.add("translate-x-full")

    // transition後に backdrop を消す
    window.setTimeout(() => {
      this.backdropTarget.classList.add("hidden")
      this.backdropTarget.classList.remove("block")
    }, 200)

    document.removeEventListener("keydown", this._onKeydown)
  }

  toggle() {
    if (this.backdropTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  closeOnBackdrop(e) {
    // backdrop 自体をクリックしたときだけ閉じる（中身クリックで閉じない）
    if (e.target === this.backdropTarget) this.close()
  }

  closeAndNavigate() {
    // メニュークリック後に閉じる（遷移はaタグ側に任せる）
    this.close()
  }

  onKeydown(e) {
    if (e.key === "Escape") this.close()
  }
}
