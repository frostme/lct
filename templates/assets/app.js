const themeToggle = document.querySelector("[data-theme-toggle]");
const preferred = window.matchMedia("(prefers-color-scheme: dark)").matches
  ? "dark"
  : "light";
const stored = localStorage.getItem("lct-theme") || preferred;

document.documentElement.dataset.theme = stored;

if (themeToggle) {
  themeToggle.addEventListener("click", () => {
    const next =
      document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    localStorage.setItem("lct-theme", next);
  });
}

const element = document.getElementById("cli_reference_icon");
if (element) {
  element.addEventListener("click", (event) => {
    event.preventDefault();
    const isOpen = element.classList.contains("open");
    const submenu = document.getElementById("cli_reference_menu");
    if (isOpen) {
      element.classList.remove("open");
      submenu.classList.remove("open");
    } else {
      element.classList.add("open");
      submenu.classList.add("open");
    }
  });
}
