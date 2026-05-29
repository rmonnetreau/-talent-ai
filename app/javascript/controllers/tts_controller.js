import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autoplay: Boolean, chatId: String }

  connect() {
    this.addSpeakerButton()
    if (this.autoplayValue && this.isAudioMode()) this.speak()
  }

  isAudioMode() {
    return (localStorage.getItem(`chat_mode_${this.chatIdValue}`) || "audio") === "audio"
  }

  disconnect() {
    if (this.audio) {
      this.audio.pause()
      this.audio.currentTime = 0
    }
  }

  toggleSpeech() {
    if (this.audio && !this.audio.paused) {
      this.stop()
    } else {
      this.speak()
    }
  }

  async speak() {
    const text = this.element.querySelector(".message-body")?.textContent?.trim()
    if (!text) return

    setTimeout(() => document.dispatchEvent(new CustomEvent("tts:loading")), 0)

    let audio
    try {
      audio = await puter.ai.txt2speech(text, {
        provider: "openai",
        model: "tts-1",
        voice: "echo"
      })
    } catch {
      document.dispatchEvent(new CustomEvent("tts:ended"))
      return
    }

    this.audio = audio
    this.audio.onended = () => {
      this.setPlaying(false)
      document.dispatchEvent(new CustomEvent("tts:ended"))
    }

    this.setPlaying(true)
    document.dispatchEvent(new CustomEvent("tts:start"))
    this.audio.play().catch(() => {})
  }

  stop() {
    if (this.audio) {
      this.audio.pause()
      this.audio.currentTime = 0
    }
    this.setPlaying(false)
    document.dispatchEvent(new CustomEvent("tts:ended"))
  }

  addSpeakerButton() {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "tts-btn"
    btn.innerHTML = "<i class=\"fa-solid fa-volume-high\"></i>"
    btn.title = "Écouter"
    btn.setAttribute("data-action", "click->tts#toggleSpeech")
    this.speakerBtn = btn
    this.element.appendChild(btn)
  }

  setPlaying(playing) {
    if (!this.speakerBtn) return
    this.speakerBtn.innerHTML = playing
      ? "<i class=\"fa-solid fa-volume-xmark\"></i>"
      : "<i class=\"fa-solid fa-volume-high\"></i>"
    this.speakerBtn.title = playing ? "Arrêter" : "Écouter"
    this.speakerBtn.classList.toggle("tts-btn--playing", playing)
  }
}
