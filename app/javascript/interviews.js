// Toggle interview card collapse
document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".toggle-card").forEach((btn, index) => {
    const id = btn.dataset.interviewId;
    const body = document.getElementById(`interview-body-${id}`);
    const svg = btn.querySelector("svg polyline");

    if (index !== 0) {
      body.classList.add("collapsed");
      svg.setAttribute("points", "6 9 12 15 18 9");
    }

    btn.addEventListener("click", () => {
      body.classList.toggle("collapsed");
      svg.setAttribute("points", body.classList.contains("collapsed") ? "6 9 12 15 18 9" : "18 15 12 9 6 15");
    });
  });
});
