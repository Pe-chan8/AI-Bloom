import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String,
    params: String,
  }

  connect() {
    const name = this.nameValue
    const params = this.parseParams(this.paramsValue)

    // layout から <html data-env="..."> を渡す前提
    const env = document.documentElement.dataset.env || "unknown"
    const isProd = env === "production"

    // 開発ではGAに送らず、consoleで発火確認だけする（GA汚染防止）
    if (!isProd) {
      console.log("[GA DEV]", name, params)
      this.element.remove()
      return
    }

    if (typeof gtag !== "function") {
      console.log("[GA] gtag not ready", name, params)
      this.element.remove()
      return
    }

    // 追加：ユーザープロパティ設定
    if (name === "set_user_properties") {
      if (params && Object.keys(params).length > 0) {
        gtag("set", "user_properties", params)
        console.log("[GA] set user_properties", params)
      } else {
        console.log("[GA] skip set_user_properties (no params)")
      }
      this.element.remove()
      return
    }

    // 通常イベント
    if (params && Object.keys(params).length > 0) {
      gtag("event", name, params)
    } else {
      gtag("event", name)
    }

    // 1回送ったら自分を消す（多重送信を抑える）
    this.element.remove()
  }

  parseParams(raw) {
    if (!raw) return null
    try {
      return JSON.parse(raw)
    } catch (e) {
      console.log("[GA] invalid params JSON", raw, e)
      return null
    }
  }
}
