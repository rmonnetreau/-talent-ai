import { Controller } from "@hotwired/stimulus"

class WaveCurve {
  constructor(opt) {
    this.controller = opt.controller
    this.color = opt.color
    this.tick = 0
    this.respawn()
  }

  respawn() {
    this.amplitude = 0.3 + (Math.random() * 0.7)
    this.seed = Math.random()
    this.open_class = 2 + (Math.random() * 3)
  }

  equation(i) {
    const y = (-1 * Math.abs(Math.sin(this.tick)))
      * (this.controller.amplitude * this.amplitude)
      * this.controller.MAX
      * (1 / ((1 + ((this.open_class * i) ** 2)) ** 2))
    if (Math.abs(y) < 0.001) this.respawn()
    return y
  }

  dram(m) {
    this.tick += this.controller.speed * (1 - (0.5 * Math.sin(this.seed * Math.PI)))
    const ctx = this.controller.ctx
    ctx.beginPath()
    const xBase = (this.controller.width / 2)
      + ((-this.controller.width / 4) + (this.seed * (this.controller.width / 2)))
    const yBase = this.controller.height / 2
    let xInit
    let i = -3
    while (i <= 3) {
      const x = xBase + ((i * this.controller.width) / 4)
      const y = yBase + (m * this.equation(i))
      xInit = xInit || x
      ctx.lineTo(x, y)
      i += 0.01
    }
    const h = Math.abs(this.equation(0))
    const gradient = ctx.createRadialGradient(xBase, yBase, h * 1.15, xBase, yBase, h * 0.3)
    gradient.addColorStop(0, `rgba(${this.color.join(',')},0.4)`)
    gradient.addColorStop(1, `rgba(${this.color.join(',')},0.2)`)
    ctx.fillStyle = gradient
    ctx.lineTo(xInit, yBase)
    ctx.closePath()
    ctx.fill()
  }

  draw() {
    this.dram(-1)
    this.dram(1)
  }
}

class VoiceWaves {
  constructor(opt) {
    this.run = false
    this.ratio = window.devicePixelRatio || 1
    this.width = this.ratio * (opt.width || 250)
    this.height = this.ratio * (opt.height || 60)
    this.MAX = this.height / 2
    this.speed = opt.speed || 0.2
    this.amplitude = opt.amplitude || 1
    this.colors = [[32, 133, 252], [94, 252, 169], [253, 71, 103]]

    this.canvas = document.createElement("canvas")
    this.canvas.width = this.width
    this.canvas.height = this.height
    this.canvas.style.width = `${this.width / this.ratio}px`
    this.canvas.style.height = `${this.height / this.ratio}px`
    opt.container.appendChild(this.canvas)
    this.ctx = this.canvas.getContext("2d")

    this.curves = []
    for (const color of this.colors) {
      const count = Math.max(1, Math.floor(3 * Math.random()))
      for (let j = 0; j < count; j++) {
        this.curves.push(new WaveCurve({ controller: this, color }))
      }
    }
  }

  clear() {
    this.ctx.globalCompositeOperation = "destination-out"
    this.ctx.fillRect(0, 0, this.width, this.height)
    this.ctx.globalCompositeOperation = "lighter"
  }

  draw() {
    if (!this.run) return
    this.clear()
    for (const curve of this.curves) curve.draw()
    requestAnimationFrame(this.draw.bind(this))
  }

  start() {
    this.run = true
    this.draw()
  }

  stop() {
    this.run = false
  }
}

export default class extends Controller {
  connect() {
    this.waves = new VoiceWaves({ width: 600, height: 60, container: this.element })

    this.loadingEl = document.createElement("div")
    this.loadingEl.className = "waveform-loading d-none"
    this.loadingEl.innerHTML = "<span></span><span></span><span></span>"
    this.element.appendChild(this.loadingEl)

    this.onLoading = () => {
      this.element.classList.remove("d-none")
      this.waves.canvas.classList.add("d-none")
      this.loadingEl.classList.remove("d-none")
    }
    this.onStart = () => {
      this.loadingEl.classList.add("d-none")
      this.waves.canvas.classList.remove("d-none")
      this.element.classList.remove("d-none")
      this.waves.start()
    }
    this.onEnd = () => {
      this.waves.stop()
      this.loadingEl.classList.add("d-none")
      this.waves.canvas.classList.add("d-none")
      this.element.classList.add("d-none")
    }


    document.addEventListener("tts:loading", this.onLoading)
    document.addEventListener("tts:start", this.onStart)
    document.addEventListener("tts:ended", this.onEnd)
  }

  disconnect() {
    this.waves?.stop()
    document.removeEventListener("tts:loading", this.onLoading)
    document.removeEventListener("tts:start", this.onStart)
    document.removeEventListener("tts:ended", this.onEnd)
  }
}
