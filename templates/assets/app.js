const themeToggle = document.querySelector("[data-theme-toggle]");
const preferred = window.matchMedia("(prefers-color-scheme: dark)").matches
  ? "dark"
  : "light";
const stored = localStorage.getItem("lct-theme") || preferred;

document.documentElement.dataset.theme = stored;

if (themeToggle) {
  themeToggle.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    localStorage.setItem("lct-theme", next);
  });
}
