(function () {
  const menuButton = document.querySelector("[data-menu]");
  const links = document.querySelector("[data-links]");
  if (!menuButton || !links) return;

  menuButton.addEventListener("click", () => {
    links.classList.toggle("open");
    const expanded = links.classList.contains("open");
    menuButton.setAttribute("aria-expanded", String(expanded));
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 760) {
      links.classList.remove("open");
      menuButton.setAttribute("aria-expanded", "false");
    }
  });
})();

