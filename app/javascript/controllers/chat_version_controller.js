import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { chatId: String }
  static targets = ["switchBtn", "audio", "text"]

  connect() {
    const key = `chat_mode_${this.chatIdValue}`
    const urlMode = new URLSearchParams(window.location.search).get("mode")
    this.mode = urlMode || localStorage.getItem(key) || "audio"
    if (urlMode) localStorage.setItem(key, this.mode)
    this.apply()
  }

  toggle() {
    this.mode = this.mode === "audio" ? "text" : "audio"
    localStorage.setItem(`chat_mode_${this.chatIdValue}`, this.mode)
    this.apply()
  }

  apply() {
    const isAudio = this.mode === "audio"
    this.audioTargets.forEach(el => el.classList.toggle("d-none", !isAudio))
    this.textTargets.forEach(el => el.classList.toggle("d-none", isAudio))
    this.switchBtnTarget.setAttribute("data-mode", this.mode)
    this.switchBtnTarget.querySelector("[data-label]").textContent =
      isAudio ? "🎤 Mode audio" : "⌨️ Mode texte"
  }
}
