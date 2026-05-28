import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status"]

  connect() {
    console.log("[VoiceInput] connect()")
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SpeechRecognition) {
      console.warn("[VoiceInput] SpeechRecognition non disponible")
      this.statusTarget.textContent = "Reconnaissance vocale non disponible sur ce navigateur."
      this.buttonTarget.disabled = true
      return
    }

    this.recognition = new SpeechRecognition()
    this.recognition.lang = "fr-FR"
    this.recognition.continuous = false
    this.recognition.interimResults = false

    this.recognition.onresult = (e) => this.onSpeechResult(e)
    this.recognition.onerror = (e) => this.onSpeechError(e)
    this.recognition.onend = () => {
      console.log("[VoiceInput] recognition.onend — state:", this.state)
      if (this.state === "listening") this.setState("idle")
    }

    this.boundTtsEnded = this.onTtsEnded.bind(this)
    document.addEventListener("tts:ended", this.boundTtsEnded)

    this.setState("idle")
    console.log("[VoiceInput] prêt")
  }

  disconnect() {
    document.removeEventListener("tts:ended", this.boundTtsEnded)
    if (this.recognition) this.recognition.abort()
    clearTimeout(this.stopTimeout)
    clearTimeout(this.processingTimeout)
  }

  startListening() {
    if (this.state !== "idle") return
    console.log("[VoiceInput] startListening()")
    this.setState("listening")
    try {
      this.recognition.start()
      console.log("[VoiceInput] recognition.start() OK")
    } catch (e) {
      console.error("[VoiceInput] recognition.start() ERREUR:", e)
      this.setState("idle")
    }
  }

  stopListening() {
    if (this.state !== "listening") return
    console.log("[VoiceInput] stopListening() — reconnaissance en cours de finalisation")
    // Délai pour laisser le temps à Chrome d'envoyer l'audio à Google et recevoir le résultat
    this.stopTimeout = setTimeout(() => {
      console.log("[VoiceInput] recognition.stop()")
      this.recognition.stop()
    }, 400)
  }

  onSpeechResult(event) {
    clearTimeout(this.stopTimeout)
    const transcript = event.results[0][0].transcript.trim()
    console.log("[VoiceInput] onSpeechResult — transcript:", transcript)

    if (!transcript) {
      console.warn("[VoiceInput] transcript vide")
      this.setState("idle")
      return
    }

    this.statusTarget.textContent = `"${transcript}"`
    this.state = "processing"
    this.buttonTarget.dataset.state = "processing"
    this.buttonTarget.disabled = true

    const container = document.getElementById("new_message_container")
    const form = container?.querySelector("form")
    const input = container?.querySelector("textarea, input[name*='content']")

    console.log("[VoiceInput] container:", container)
    console.log("[VoiceInput] form:", form)
    console.log("[VoiceInput] input:", input)

    if (!form || !input) {
      console.error("[VoiceInput] formulaire ou input introuvable !")
      this.statusTarget.textContent = "Erreur : formulaire introuvable."
      setTimeout(() => this.setState("idle"), 2000)
      return
    }

    input.value = transcript
    console.log("[VoiceInput] input.value défini:", input.value)

    this.processingTimeout = setTimeout(() => {
      if (this.state === "processing") this.setState("idle")
    }, 30000)

    setTimeout(() => {
      console.log("[VoiceInput] requestSubmit()")
      this.statusTarget.textContent = "Réfléchit…"
      form.requestSubmit()
    }, 600)
  }

  onSpeechError(event) {
    console.error("[VoiceInput] onerror:", event.error)
    const messages = {
      "no-speech": "Aucune parole détectée, réessayez.",
      "network": "Erreur réseau (Speech API).",
      "not-allowed": "Microphone non autorisé.",
      "audio-capture": "Microphone introuvable."
    }
    this.statusTarget.textContent = messages[event.error] || `Erreur: ${event.error}`
    setTimeout(() => {
      if (this.state !== "processing") this.setState("idle")
    }, 2500)
  }

  onTtsEnded() {
    console.log("[VoiceInput] tts:ended reçu")
    clearTimeout(this.processingTimeout)
    if (this.state === "processing") this.setState("idle")
  }

  setState(state) {
    this.state = state
    const labels = {
      idle: "Maintenez pour parler",
      listening: "Écoute…",
      processing: "Réfléchit…"
    }
    if (labels[state]) this.statusTarget.textContent = labels[state]
    this.buttonTarget.dataset.state = state
    this.buttonTarget.disabled = state === "processing"
  }
}
