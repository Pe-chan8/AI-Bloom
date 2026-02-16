import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Turbo Stream invoke 用（互換維持）
    this.element.post_created = this.post_created.bind(this)
    this.element.buddy_talk_created = this.buddy_talk_created.bind(this)

    // 初回 + Turbo遷移でも user_properties をセットできるようにする
    this.setUserProperties = this.setUserProperties.bind(this)

    // 初回
    this.setUserProperties()

    // Turbo対応（遷移/復元/フレーム置換など）
    document.addEventListener("turbo:load", this.setUserProperties)
    document.addEventListener("turbo:render", this.setUserProperties)

    // DEVログ
    if (this.isDev()) console.log("ga controller connected")
  }

  disconnect() {
    delete this.element.post_created
    delete this.element.buddy_talk_created

    document.removeEventListener("turbo:load", this.setUserProperties)
    document.removeEventListener("turbo:render", this.setUserProperties)
  }

  isDev() {
    return document.documentElement?.dataset?.env === "development"
  }

  // user_property をGA4へ送信
  setUserProperties() {
    const dominantType = document.body?.dataset?.userDominantType
    if (!dominantType) return

    if (this.isDev()) {
      console.log("[GA DEV] set user_properties", { dominant_type: dominantType })
    }

    if (typeof gtag === "function") {
      gtag("set", "user_properties", { dominant_type: dominantType })
      gtag("event", "diagnosis_completed")
    } else {
      if (this.isDev()) console.log("[GA DEV] gtag not ready (user_properties)")
    }
  }

  // 旧名：互換のため残す
  post_created() {
    this.buddy_talk_created()
  }

  buddy_talk_created() {
    if (this.isDev()) console.log("[GA DEV] buddy_talk_created")

    if (typeof gtag === "function") {
      gtag("event", "buddy_talk_created")
    }
  }
}
