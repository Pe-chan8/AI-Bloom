import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String,
    params: String,
  }

  connect() {
    const name = this.nameValue
    const params = this.parseParams(this.paramsValue)

    const env = document.documentElement.dataset.env || "unknown"
    const isProd = env === "production"

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

    // user_property セット（永続化）
    if (name === "set_user_properties") {
      if (params && Object.keys(params).length > 0) {
        gtag("set", "user_properties", params)
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
