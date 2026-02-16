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

  // user_property をGA4へ送信（Turbo遷移でも拾う）
  // ※ user_property は「その後のイベント」に紐づいて初めて集計に乗りやすいので
  //    初回のみ "user_property_synced" を送る（毎回 diagnosis_completed を乱発しない）
  setUserProperties() {
    const dominantType = document.body?.dataset?.userDominantType
    if (!dominantType) return

    if (this.isDev()) {
      console.log("[GA DEV] set user_properties", { dominant_type: dominantType })
    }

    if (typeof gtag !== "function") {
      if (this.isDev()) console.log("[GA DEV] gtag not ready (user_properties)")
      return
    }

    // user_properties セット
    gtag("set", "user_properties", { dominant_type: dominantType })

    // user_propertyをGA側に“確実に紐づける”ための1回だけのイベント
    // - Turboで遷移するたびに発火しないよう localStorage で抑制
    // - dominantType が変わったら再送できるように、値もキーに含める
    try {
      const key = `ga:user_property_synced:dominant_type:${dominantType}`
      const already = window.localStorage.getItem(key)
      if (!already) {
        gtag("event", "user_property_synced")
        window.localStorage.setItem(key, "1")
        if (this.isDev()) console.log("[GA DEV] fired user_property_synced once")
      }
    } catch (e) {
      // localStorage が使えない環境でも落とさない（念のため）
      gtag("event", "user_property_synced")
      if (this.isDev()) console.log("[GA DEV] fired user_property_synced (no storage)", e)
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
