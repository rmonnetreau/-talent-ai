import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    const SpeechRecognition =
      window.SpeechRecognition || window.webkitSpeechRecognition

    if (!SpeechRecognition) {
      this.buttonTarget.disabled = true
      this.buttonTarget.innerText = "Micro non supporté"
      return
    }

    this.recognition = new SpeechRecognition()
    this.recognition.lang = "fr-FR"
    this.recognition.interimResults = true
    this.recognition.continuous = true

    this.isListening = false
    this.finalTranscript = this.inputTarget.value || ""

    this.recognition.onresult = (event) => {
      let interimTranscript = ""

      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript

        if (event.results[i].isFinal) {
          this.finalTranscript += transcript + " "
        } else {
          interimTranscript += transcript
        }
      }

      this.inputTarget.value = this.finalTranscript + interimTranscript
    }

    this.recognition.onend = () => {
      if (this.isListening) {
        this.recognition.start()
      }
    }
  }

  toggle() {
    if (this.isListening) {
      this.stop()
    } else {
      this.start()
    }
  }

start() {
  this.finalTranscript = this.inputTarget.value || ""
  this.isListening = true
  this.buttonTarget.innerHTML =
    '<i class="fa-solid fa-stop"></i>'
  this.recognition.start()
}

stop() {

  this.isListening = false
  this.buttonTarget.innerHTML =
    '<i class="fa-solid fa-microphone"></i>'
  this.recognition.stop()
}
}
