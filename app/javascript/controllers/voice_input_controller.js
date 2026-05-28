import { Controller } from "@hotwired/stimulus"

const SPEECH_ERRORS = {
  "no-speech":     "Aucune parole détectée, réessayez.",
  "network":       "Erreur réseau (Speech API).",
  "not-allowed":   "Microphone non autorisé.",
  "audio-capture": "Microphone introuvable."
}

export default class extends Controller {
  static targets = ["button", "status"]

  connect() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SpeechRecognition) {
      this.statusTarget.textContent = "Reconnaissance vocale non disponible sur ce navigateur."
      this.buttonTarget.disabled = true
      return
    }

    this.recognition = new SpeechRecognition()
    this.recognition.lang = "fr-FR"
    this.recognition.continuous = false
    this.recognition.interimResults = false

    this.recognition.onresult = (e) => this.onSpeechResult(e)
    this.recognition.onerror  = (e) => this.onSpeechError(e)
    this.recognition.onend    = () => { if (this.state === "listening") this.setState("idle") }

    this.boundTtsEnded = this.onTtsEnded.bind(this)
    document.addEventListener("tts:ended", this.boundTtsEnded)

    this.setState("idle")
  }

  disconnect() {
    document.removeEventListener("tts:ended", this.boundTtsEnded)
    this.recognition?.abort()
    clearTimeout(this.stopTimeout)
    clearTimeout(this.processingTimeout)
  }

  startListening() {
    if (this.state !== "idle") return
    this.setState("listening")
    try {
      this.recognition.start()
    } catch {
      this.setState("idle")
    }
  }

  stopListening() {
    if (this.state !== "listening") return
    // Delay lets Chrome finalize audio before stopping recognition
    this.stopTimeout = setTimeout(() => this.recognition.stop(), 400)
  }

  onSpeechResult(event) {
    clearTimeout(this.stopTimeout)
    const transcript = event.results[0][0].transcript.trim()

    if (!transcript) { this.setState("idle"); return }

    const container = document.getElementById("new_message_container")
    const form  = container?.querySelector("form")
    const input = container?.querySelector("textarea, input[name*='content']")

    if (!form || !input) {
      this.statusTarget.textContent = "Erreur : formulaire introuvable."
      setTimeout(() => this.setState("idle"), 2000)
      return
    }

    input.value = transcript
    this.statusTarget.textContent = `"${transcript}"`
    this.state = "processing"
    this.buttonTarget.dataset.state = "processing"
    this.buttonTarget.disabled = true

    this.processingTimeout = setTimeout(() => {
      if (this.state === "processing") this.setState("idle")
    }, 30000)

    setTimeout(() => {
      this.statusTarget.textContent = "Votre interlocuteur vous répond…"
      form.requestSubmit()
    }, 600)
  }

  onSpeechError(event) {
    this.statusTarget.textContent = SPEECH_ERRORS[event.error] ?? `Erreur : ${event.error}`
    setTimeout(() => { if (this.state !== "processing") this.setState("idle") }, 2500)
  }

  onTtsEnded() {
    clearTimeout(this.processingTimeout)
    if (this.state === "processing") this.setState("idle")
  }

  setState(state) {
    this.state = state
    const labels = { idle: "Vous : Maintenez pour parler", listening: "Écoute…" }
    if (labels[state]) this.statusTarget.textContent = labels[state]
    this.buttonTarget.dataset.state = state
    this.buttonTarget.disabled = state === "processing"
  }
}
