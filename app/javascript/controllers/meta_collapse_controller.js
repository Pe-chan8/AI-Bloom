import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["box", "spacer", "toggle"]
  static values = { storageKey: String, collapsed: Boolean }

  connect() {
    const key = this.storageKeyValue || "buddy-meta-collapsed"
    const saved = sessionStorage.getItem(key)
    this.collapsedValue = saved === "1"
    this.apply()
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    const key = this.storageKeyValue || "buddy-meta-collapsed"
    sessionStorage.setItem(key, this.collapsedValue ? "1" : "0")
    this.apply()
  }

  apply() {
    // メタ本体の表示/非表示
    this.boxTarget.classList.toggle("hidden", this.collapsedValue)

    // 固定メタのスペーサーも連動（チャットを広げる）
    this.spacerTarget.classList.toggle("hidden", this.collapsedValue)

    // ボタン文言
    this.toggleTarget.textContent = this.collapsedValue ? "▼開く" : "▲閉じる"
  }
}
