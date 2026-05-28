import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autoplay: Boolean }

  connect() {
    if (!window.speechSynthesis) return
    this.addSpeakerButton()
    if (this.autoplayValue) this.speakWhenReady()
  }

  speakWhenReady() {
    // speechSynthesis.speak() is blocked after async network requests in Chrome/Safari.
    // A silent utterance re-establishes the user gesture context.
    const unlock = new SpeechSynthesisUtterance("")
    unlock.volume = 0
    unlock.onend = () => this.speak()
    speechSynthesis.speak(unlock)
  }

  disconnect() {
    speechSynthesis.cancel()
  }

  toggleSpeech() {
    if (speechSynthesis.speaking) {
      this.stop()
    } else {
      this.speak()
    }
  }

  speak() {
    speechSynthesis.cancel()
    const text = this.element.querySelector(".message-body")?.textContent?.trim()
    if (!text) return

    const utterance = new SpeechSynthesisUtterance(text)
    utterance.lang = "fr-FR"
    utterance.rate = 0.9
    utterance.onstart = () => {
      this.setPlaying(true)
      document.dispatchEvent(new CustomEvent("tts:start"))
    }
    utterance.onend = () => {
      this.setPlaying(false)
      document.dispatchEvent(new CustomEvent("tts:ended"))
    }
    utterance.onerror = () => {
      this.setPlaying(false)
      document.dispatchEvent(new CustomEvent("tts:ended"))
    }
    speechSynthesis.speak(utterance)
  }

  stop() {
    speechSynthesis.cancel()
    this.setPlaying(false)
  }

  addSpeakerButton() {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "tts-btn"
    btn.innerHTML = "🔊"
    btn.title = "Écouter"
    btn.setAttribute("data-action", "click->tts#toggleSpeech")
    this.speakerBtn = btn
    this.element.appendChild(btn)
  }

  setPlaying(playing) {
    if (!this.speakerBtn) return
    this.speakerBtn.innerHTML = playing ? "⏹️" : "🔊"
    this.speakerBtn.title = playing ? "Arrêter" : "Écouter"
    this.speakerBtn.classList.toggle("tts-btn--playing", playing)
  }
}
