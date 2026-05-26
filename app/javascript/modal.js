// ── Modal ──────────────────────────────────────────────────────
window.openModal = function(chatId) {
  const modal = document.getElementById(`feedback-modal-${chatId}`);
  if (modal) {
    modal.hidden = false;
    document.body.style.overflow = "hidden";
  }
}

window.closeModal = function(chatId) {
  const modal = document.getElementById(`feedback-modal-${chatId}`);
  if (modal) {
    modal.hidden = true;
    document.body.style.overflow = "";
  }
}

// Fermer en cliquant sur l'overlay
document.addEventListener("click", (e) => {
  if (e.target.classList.contains("modal-overlay")) {
    e.target.hidden = true;
    document.body.style.overflow = "";
  }
});

// Fermer avec Escape
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    document.querySelectorAll(".modal-overlay:not([hidden])").forEach(modal => {
      modal.hidden = true;
      document.body.style.overflow = "";
    });
  }
});
