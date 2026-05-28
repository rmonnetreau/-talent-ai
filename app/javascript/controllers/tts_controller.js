import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autoplay: Boolean, chatId: Number, messageId: Number }

  connect() {
    this.addSpeakerButton()
    // Pre-load audio immediately for autoplay messages to reduce perceived latency.
    if (this.autoplayValue) {
      this.setLoading(true)
      this._preload()
        .then(() => this._playAudio())
        .catch(e => { console.error("TTS autoplay error:", e); this.setLoading(false) })
    }
  }

  disconnect() {
    this._abortController?.abort()
    this._stopAudio()
    if (this._audioUrl) URL.revokeObjectURL(this._audioUrl)
  }

  toggleSpeech() {
    if (this.audio && !this.audio.paused) {
      this._stopAudio()
      this.setPlaying(false)
    } else {
      this.play()
    }
  }

  async play() {
    this.setLoading(true)
    try {
      await this._preload()
      await this._playAudio()
    } catch (e) {
      console.error("TTS error:", e)
      this.setLoading(false)
    }
  }

  // Returns a deduplicated promise so concurrent calls share the same fetch.
  _preload() {
    if (!this._loadPromise) {
      this._abortController = new AbortController()
      this._loadPromise = (async () => {
        const url = `/chats/${this.chatIdValue}/messages/${this.messageIdValue}/audio`
        const response = await fetch(url, { signal: this._abortController.signal })
        if (!response.ok) throw new Error(`TTS fetch failed: ${response.status}`)
        const blob = await response.blob()
        this._audioUrl = URL.createObjectURL(blob)
      })()
    }
    return this._loadPromise
  }

  async _playAudio() {
    if (!this._audioUrl) return
    this._stopAudio()

    this.audio = new Audio(this._audioUrl)

    const done = () => {
      this.setPlaying(false)
      document.dispatchEvent(new CustomEvent("tts:ended"))
    }
    this.audio.onended = done
    this.audio.onerror = done

    // Dispatch tts:start only when audio is actually about to play,
    // so the waveform is visible exactly during playback (not during fetch).
    this.setPlaying(true)
    document.dispatchEvent(new CustomEvent("tts:start"))

    try {
      await this.audio.play()
    } catch {
      done()
    }
  }

  _stopAudio() {
    if (this.audio) {
      this.audio.pause()
      this.audio.currentTime = 0
    }
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

  setLoading(loading) {
    if (!this.speakerBtn) return
    this.speakerBtn.disabled = loading
    this.speakerBtn.innerHTML = loading ? "⏳" : "🔊"
    this.speakerBtn.title = loading ? "Chargement…" : "Écouter"
    this.speakerBtn.classList.remove("tts-btn--playing")
  }

  setPlaying(playing) {
    if (!this.speakerBtn) return
    this.speakerBtn.disabled = false
    this.speakerBtn.innerHTML = playing ? "⏹️" : "🔊"
    this.speakerBtn.title = playing ? "Arrêter" : "Écouter"
    this.speakerBtn.classList.toggle("tts-btn--playing", playing)
  }
}
